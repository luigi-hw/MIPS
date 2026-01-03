import argparse
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class VcdVar:
    code: str
    name: str
    width: int


@dataclass
class BitCoverage:
    seen0: bool = False
    seen1: bool = False

    def add(self, ch: str) -> None:
        if ch == "0":
            self.seen0 = True
        elif ch == "1":
            self.seen1 = True

    def covered(self) -> bool:
        return self.seen0 and self.seen1


@dataclass
class VarCoverage:
    bits: list[BitCoverage]

    @classmethod
    def for_width(cls, width: int) -> "VarCoverage":
        return cls(bits=[BitCoverage() for _ in range(width)])

    def add_scalar(self, ch: str) -> None:
        self.bits[0].add(ch)

    def add_vector(self, binstr: str) -> None:
        s = binstr.strip().lower()
        if len(s) < len(self.bits):
            s = s.zfill(len(self.bits))
        if len(s) > len(self.bits):
            s = s[-len(self.bits) :]
        for i, ch in enumerate(s):
            self.bits[i].add(ch)

    def covered_bits(self) -> int:
        return sum(1 for b in self.bits if b.covered())

    def total_bits(self) -> int:
        return len(self.bits)

    def covered(self) -> bool:
        return self.covered_bits() == self.total_bits()


def _hier_join(stack: list[str], ref: str) -> str:
    if not stack:
        return ref
    return ".".join(stack + [ref])


def parse_vcd_definitions(vcd_path: Path) -> tuple[dict[str, VcdVar], dict[str, str]]:
    vars_by_code: dict[str, VcdVar] = {}
    code_to_scope: dict[str, str] = {}
    scope_stack: list[str] = []

    with vcd_path.open("r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("$scope"):
                parts = line.split()
                if len(parts) >= 3:
                    scope_stack.append(parts[2])
                continue
            if line.startswith("$upscope"):
                if scope_stack:
                    scope_stack.pop()
                continue
            if line.startswith("$var"):
                parts = line.split()
                if len(parts) < 5:
                    continue
                width = int(parts[2])
                code = parts[3]
                ref = parts[4]
                full_name = _hier_join(scope_stack, ref)
                vars_by_code[code] = VcdVar(code=code, name=full_name, width=width)
                code_to_scope[code] = ".".join(scope_stack)
                continue
            if line.startswith("$enddefinitions"):
                break

    return vars_by_code, code_to_scope


def find_signal_code(vars_by_code: dict[str, VcdVar], suffix: str) -> str | None:
    matches = [v.code for v in vars_by_code.values() if v.name.endswith(suffix)]
    if len(matches) == 1:
        return matches[0]
    if not matches:
        return None
    matches_sorted = sorted(
        matches,
        key=lambda c: len(vars_by_code[c].name),
    )
    return matches_sorted[0]


def decode_u32(binstr: str) -> int | None:
    s = binstr.strip().lower()
    if any(ch in "xz" for ch in s):
        return None
    try:
        return int(s, 2)
    except ValueError:
        return None


def instr_fields(instr: int) -> dict[str, int]:
    opcode = (instr >> 26) & 0x3F
    rs = (instr >> 21) & 0x1F
    rt = (instr >> 16) & 0x1F
    rd = (instr >> 11) & 0x1F
    shamt = (instr >> 6) & 0x1F
    funct = instr & 0x3F
    imm = instr & 0xFFFF
    return {
        "opcode": opcode,
        "rs": rs,
        "rt": rt,
        "rd": rd,
        "shamt": shamt,
        "funct": funct,
        "imm": imm,
    }


def is_probably_constant_symbol(full_name: str) -> bool:
    leaf = full_name.split(".")[-1]
    if not leaf:
        return False
    if not all(ch.isupper() or ch.isdigit() or ch == "_" for ch in leaf):
        return False
    return any(ch.isupper() for ch in leaf)


def should_ignore_for_coverage(scope: str, full_name: str, include_tb: bool) -> bool:
    if not include_tb and not scope.startswith("tb_mips_top.uut"):
        return True
    if scope.startswith("tb_mips_top.check_"):
        return True
    if is_probably_constant_symbol(full_name):
        return True
    return False


def analyze_vcd(vcd_path: Path, *, include_tb: bool) -> dict[str, object]:
    vars_by_code, code_to_scope = parse_vcd_definitions(vcd_path)
    cov_by_code: dict[str, VarCoverage] = {c: VarCoverage.for_width(v.width) for c, v in vars_by_code.items()}

    clk_code = find_signal_code(vars_by_code, ".clk")
    pc_code = find_signal_code(vars_by_code, ".uut.program_counter")
    instr_code = find_signal_code(vars_by_code, ".uut.instruction")

    last_scalar: dict[str, str] = {}
    last_vector: dict[str, str] = {}

    clk_prev = None
    executed_pcs: list[int] = []
    executed_instrs: list[int] = []
    opcode_hist = defaultdict(int)
    funct_hist = defaultdict(int)
    regimm_rt_hist = defaultdict(int)

    def sample_on_rising_edge() -> None:
        if pc_code is None or instr_code is None:
            return
        pc_bin = last_vector.get(pc_code)
        instr_bin = last_vector.get(instr_code)
        if pc_bin is None or instr_bin is None:
            return
        pc_val = decode_u32(pc_bin)
        instr_val = decode_u32(instr_bin)
        if pc_val is None or instr_val is None:
            return
        executed_pcs.append(pc_val)
        executed_instrs.append(instr_val)
        fields = instr_fields(instr_val)
        op = fields["opcode"]
        opcode_hist[op] += 1
        if op == 0:
            funct_hist[fields["funct"]] += 1
        if op == 1:
            regimm_rt_hist[fields["rt"]] += 1

    with vcd_path.open("r", encoding="utf-8", errors="replace") as f:
        in_dump = False
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if not in_dump:
                if line.startswith("$enddefinitions"):
                    in_dump = True
                continue
            if line.startswith("$"):
                continue
            if line[0] == "#":
                continue

            if line[0] in "01xz":
                ch = line[0].lower()
                code = line[1:].strip()
                if code in cov_by_code:
                    cov_by_code[code].add_scalar(ch)
                    last_scalar[code] = ch
                if code == clk_code:
                    if clk_prev is None:
                        clk_prev = ch
                    else:
                        if clk_prev == "0" and ch == "1":
                            sample_on_rising_edge()
                        clk_prev = ch
                continue

            if line[0] in "bB":
                try:
                    _, rest = line[0], line[1:].strip()
                    value, code = rest.split(None, 1)
                except ValueError:
                    continue
                code = code.strip()
                if code in cov_by_code:
                    cov_by_code[code].add_vector(value)
                    last_vector[code] = value
                continue

    per_scope_bits = defaultdict(lambda: {"covered": 0, "total": 0})
    per_var = []
    for code, var in vars_by_code.items():
        scope = code_to_scope.get(code, "")
        if should_ignore_for_coverage(scope, var.name, include_tb):
            continue
        vc = cov_by_code[code]
        covered_bits = vc.covered_bits()
        total_bits = vc.total_bits()
        per_scope_bits[scope]["covered"] += covered_bits
        per_scope_bits[scope]["total"] += total_bits
        per_var.append((covered_bits, total_bits, var.name, code))

    per_var.sort(key=lambda t: (t[0] / t[1] if t[1] else 0.0, t[1]), reverse=False)

    return {
        "vars_by_code": vars_by_code,
        "coverage_by_code": cov_by_code,
        "per_scope_bits": per_scope_bits,
        "per_var_sorted": per_var,
        "clk_code": clk_code,
        "pc_code": pc_code,
        "instr_code": instr_code,
        "executed_pcs": executed_pcs,
        "executed_instrs": executed_instrs,
        "opcode_hist": dict(opcode_hist),
        "funct_hist": dict(funct_hist),
        "regimm_rt_hist": dict(regimm_rt_hist),
    }


def format_percent(num: int, den: int) -> str:
    if den == 0:
        return "n/a"
    return f"{(100.0 * num / den):.2f}%"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Cobertura por toggle (VCD) + histogramas de instrução (MIPS).")
    ap.add_argument("--vcd", default="tb_mips_top.vcd", help="Caminho para o arquivo .vcd")
    ap.add_argument("--include-tb", action="store_true", help="Inclui sinais do testbench na cobertura toggle")
    ap.add_argument("--top-uncovered", type=int, default=30, help="Quantidade de sinais menos cobertos a listar")
    ap.add_argument("--scopes", type=int, default=20, help="Quantidade de scopes a listar")
    args = ap.parse_args(argv)

    vcd_path = Path(args.vcd)
    if not vcd_path.exists():
        print(f"Arquivo VCD não encontrado: {vcd_path}", file=sys.stderr)
        return 2

    r = analyze_vcd(vcd_path, include_tb=args.include_tb)
    per_scope_bits: dict[str, dict[str, int]] = r["per_scope_bits"]  # type: ignore[assignment]
    per_var_sorted: list[tuple[int, int, str, str]] = r["per_var_sorted"]  # type: ignore[assignment]

    total_cov = 0
    total_bits = 0
    for scope, agg in per_scope_bits.items():
        total_cov += agg["covered"]
        total_bits += agg["total"]

    print("=================================================================")
    print("Cobertura (toggle) baseada em VCD")
    print("=================================================================")
    print(f"Bits cobertos: {total_cov}/{total_bits} ({format_percent(total_cov, total_bits)})")
    print("")

    scopes_sorted = sorted(
        per_scope_bits.items(),
        key=lambda kv: (kv[1]["covered"] / kv[1]["total"] if kv[1]["total"] else 0.0, kv[1]["total"]),
    )
    print("Scopes menos cobertos:")
    for scope, agg in scopes_sorted[: args.scopes]:
        print(f"- {scope or '<root>'}: {agg['covered']}/{agg['total']} ({format_percent(agg['covered'], agg['total'])})")
    print("")

    print("Sinais menos cobertos:")
    for covered, total, name, _code in per_var_sorted[: args.top_uncovered]:
        print(f"- {name}: {covered}/{total} ({format_percent(covered, total)})")
    print("")

    print("=================================================================")
    print("Cobertura funcional (amostrada em borda de subida do clock)")
    print("=================================================================")
    clk_code = r["clk_code"]
    pc_code = r["pc_code"]
    instr_code = r["instr_code"]
    if clk_code is None or pc_code is None or instr_code is None:
        print("Não consegui localizar automaticamente clk/pc/instruction no VCD.")
    else:
        executed_pcs: list[int] = r["executed_pcs"]  # type: ignore[assignment]
        executed_instrs: list[int] = r["executed_instrs"]  # type: ignore[assignment]
        opcode_hist: dict[int, int] = r["opcode_hist"]  # type: ignore[assignment]
        funct_hist: dict[int, int] = r["funct_hist"]  # type: ignore[assignment]
        regimm_rt_hist: dict[int, int] = r["regimm_rt_hist"]  # type: ignore[assignment]

        print(f"Instrucões amostradas: {len(executed_instrs)}")
        if executed_pcs:
            uniq_pcs = sorted(set(executed_pcs))
            print(f"PCs únicos: {len(uniq_pcs)} (min={min(uniq_pcs)}, max={max(uniq_pcs)})")

        opcodes_sorted = sorted(opcode_hist.items(), key=lambda kv: kv[0])
        print("")
        print("Opcodes executados (hex):")
        print(" ".join(f"{op:02x}({cnt})" for op, cnt in opcodes_sorted))

        if funct_hist:
            funct_sorted = sorted(funct_hist.items(), key=lambda kv: kv[0])
            print("")
            print("SPECIAL funct executados (hex):")
            print(" ".join(f"{fn:02x}({cnt})" for fn, cnt in funct_sorted))

        if regimm_rt_hist:
            rt_sorted = sorted(regimm_rt_hist.items(), key=lambda kv: kv[0])
            print("")
            print("REGIMM rt executados (bin/dec):")
            print(" ".join(f"{rt:05b}({rt})[{cnt}]" for rt, cnt in rt_sorted))

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

