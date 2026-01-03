import argparse
import json
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Probe:
    name: str
    kind: str  # "line" | "branch"
    file: str
    line: int
    detail: str


@dataclass(frozen=True)
class VcdVar:
    code: str
    name: str
    width: int


def _hier_join(stack: list[str], ref: str) -> str:
    if not stack:
        return ref
    return ".".join(stack + [ref])


def parse_vcd_definitions(vcd_path: Path) -> dict[str, VcdVar]:
    vars_by_code: dict[str, VcdVar] = {}
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
                continue
            if line.startswith("$enddefinitions"):
                break

    return vars_by_code


def parse_vcd_scalar_ones(vcd_path: Path, target_codes: set[str]) -> set[str]:
    hit: set[str] = set()
    if not target_codes:
        return hit

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
            if line.startswith("$") or line[0] == "#":
                continue
            if line[0] not in "01xXzZ":
                continue
            code = line[1:].strip()
            if code not in target_codes or code in hit:
                continue
            ch = line[0]
            if ch == "1":
                hit.add(code)
                if len(hit) == len(target_codes):
                    return hit
    return hit


_RE_MODULE = re.compile(r"^\s*module\s+([a-zA-Z_][a-zA-Z0-9_$]*)\b")
_RE_ENDMODULE = re.compile(r"^\s*endmodule\b")
_RE_ALWAYS_OR_INITIAL = re.compile(r"^\s*(always|initial)\b")
_RE_BEGIN = re.compile(r"^\s*begin\b")
_RE_END = re.compile(r"^\s*end\b")
_RE_ELSE = re.compile(r"^\s*else\b")
_RE_IF = re.compile(r"^\s*if\s*\(")
_RE_CASE = re.compile(r"^\s*case(z|x)?\s*\(")
_RE_ENDCASE = re.compile(r"^\s*endcase\b")
_RE_CASE_ITEM = re.compile(r"^\s*(default\s*:|[^:\s][^:]*:)\s*(begin\b)?\s*$")


def _strip_inline_comment(s: str) -> str:
    idx = s.find("//")
    if idx == -1:
        return s
    return s[:idx]


def instrument_verilog_file(src_path: Path, dst_path: Path, *, probe_start_id: int) -> tuple[list[Probe], int]:
    src_lines = src_path.read_text(encoding="utf-8", errors="replace").splitlines(keepends=True)

    def indent_of(s: str) -> str:
        m = re.match(r"^\s*", s)
        return m.group(0) if m else ""

    def child_indent(indent: str) -> str:
        return indent + ("\t" if "\t" in indent else "    ")

    def emit_probe_stmt(indent: str, probe_name: str) -> str:
        return f"{indent}{probe_name} = 1'b1;\n"

    def instrument_module_chunk(chunk_lines: list[str], *, start_line_no: int, probe_id_in: int) -> tuple[list[str], list[Probe], int]:
        probe_id = probe_id_in
        chunk_out: list[str] = []
        chunk_probes: list[Probe] = []
        used_probe_names: list[str] = []

        def new_probe(kind: str, abs_line_no: int, detail: str) -> str:
            nonlocal probe_id
            probe_id += 1
            name = f"__cov_{'L' if kind == 'line' else 'B'}{probe_id:06d}"
            chunk_probes.append(Probe(name=name, kind=kind, file=str(src_path), line=abs_line_no, detail=detail))
            used_probe_names.append(name)
            return name

        mod_indent = indent_of(chunk_lines[0]) if chunk_lines else ""
        port_end_idx: int | None = None
        for k, raw in enumerate(chunk_lines):
            s = _strip_inline_comment(raw).strip()
            if ");" in s:
                port_end_idx = k
                break
        if port_end_idx is None:
            port_end_idx = 0

        chunk_out.extend(chunk_lines[: port_end_idx + 1])
        chunk_out.append("__COV_DECLS__\n")

        i = port_end_idx + 1

        in_proc = False
        proc_depth = 0
        awaiting_proc_begin = False
        pending_then_branch_probe: str | None = None
        pending_else_branch_probe: str | None = None
        pending_case_item_probe: str | None = None
        case_depth = 0

        def next_stmt_index(from_idx: int) -> int | None:
            k = from_idx
            while k < len(chunk_lines):
                s = _strip_inline_comment(chunk_lines[k]).strip()
                if s:
                    return k
                k += 1
            return None

        while i < len(chunk_lines):
            raw = chunk_lines[i]
            abs_line = start_line_no + i
            stripped = _strip_inline_comment(raw).strip()

            if _RE_ENDMODULE.match(raw):
                chunk_out.append(raw)
                break

            if _RE_ALWAYS_OR_INITIAL.match(raw):
                chunk_out.append(raw)
                in_proc = True
                proc_depth = 0
                awaiting_proc_begin = True
                i += 1
                continue

            if in_proc and awaiting_proc_begin:
                chunk_out.append(raw)
                if _RE_BEGIN.match(stripped) or stripped.endswith("begin"):
                    proc_depth = 1
                    awaiting_proc_begin = False
                i += 1
                continue

            if in_proc:
                if _RE_BEGIN.match(stripped) or stripped == "begin":
                    proc_depth += 1
                    chunk_out.append(raw)
                    begin_indent = child_indent(indent_of(raw))
                    if pending_then_branch_probe is not None:
                        chunk_out.append(emit_probe_stmt(begin_indent, pending_then_branch_probe))
                        pending_then_branch_probe = None
                    elif pending_else_branch_probe is not None:
                        chunk_out.append(emit_probe_stmt(begin_indent, pending_else_branch_probe))
                        pending_else_branch_probe = None
                    elif pending_case_item_probe is not None:
                        chunk_out.append(emit_probe_stmt(begin_indent, pending_case_item_probe))
                        pending_case_item_probe = None
                    i += 1
                    continue

                if _RE_END.match(stripped) or stripped == "end":
                    proc_depth = max(0, proc_depth - 1)
                    chunk_out.append(raw)
                    if proc_depth == 0:
                        in_proc = False
                        awaiting_proc_begin = False
                        case_depth = 0
                    i += 1
                    continue

                if _RE_ENDCASE.match(stripped):
                    if case_depth > 0:
                        case_depth -= 1
                    chunk_out.append(raw)
                    i += 1
                    continue

                if proc_depth == 0:
                    chunk_out.append(raw)
                    i += 1
                    continue

                if _RE_ELSE.match(stripped):
                    nxt = next_stmt_index(i + 1)
                    if nxt is not None:
                        nxt_s = _strip_inline_comment(chunk_lines[nxt]).strip()
                        if nxt_s and not _RE_BEGIN.match(nxt_s):
                            raw_no_nl = raw[:-1] if raw.endswith("\n") else raw
                            if "//" in raw_no_nl:
                                code_part, comment_part = raw_no_nl.split("//", 1)
                                comment_part = "//" + comment_part
                            else:
                                code_part, comment_part = raw_no_nl, ""

                            br = new_probe("branch", abs_line, "else")
                            ln_body = new_probe("line", start_line_no + nxt, "stmt")
                            indent = indent_of(raw)
                            chunk_out.append(f"{code_part.rstrip()} begin {comment_part}\n" if comment_part else f"{code_part.rstrip()} begin\n")
                            body_indent = child_indent(indent)
                            chunk_out.append(emit_probe_stmt(body_indent, br))
                            chunk_out.append(emit_probe_stmt(body_indent, ln_body))
                            chunk_out.append(f"{body_indent}{_strip_inline_comment(chunk_lines[nxt]).strip()}\n")
                            chunk_out.append(f"{indent}end\n")
                            i = nxt + 1
                            continue

                    pending_else_branch_probe = new_probe("branch", abs_line, "else")
                    chunk_out.append(raw)
                    i += 1
                    continue

                if _RE_IF.match(stripped):
                    line_probe = new_probe("line", abs_line, "if")
                    chunk_out.append(emit_probe_stmt(indent_of(raw), line_probe))

                    if "begin" not in stripped:
                        nxt = next_stmt_index(i + 1)
                        if nxt is not None:
                            nxt_s = _strip_inline_comment(chunk_lines[nxt]).strip()
                            if nxt_s and not _RE_BEGIN.match(nxt_s) and not _RE_ELSE.match(nxt_s):
                                raw_no_nl = raw[:-1] if raw.endswith("\n") else raw
                                if "//" in raw_no_nl:
                                    code_part, comment_part = raw_no_nl.split("//", 1)
                                    comment_part = "//" + comment_part
                                else:
                                    code_part, comment_part = raw_no_nl, ""

                                br = new_probe("branch", abs_line, "if_true")
                                ln_body = new_probe("line", start_line_no + nxt, "stmt")
                                indent = indent_of(raw)
                                chunk_out.append(f"{code_part.rstrip()} begin {comment_part}\n" if comment_part else f"{code_part.rstrip()} begin\n")
                                body_indent = child_indent(indent)
                                chunk_out.append(emit_probe_stmt(body_indent, br))
                                chunk_out.append(emit_probe_stmt(body_indent, ln_body))
                                chunk_out.append(f"{body_indent}{_strip_inline_comment(chunk_lines[nxt]).strip()}\n")
                                chunk_out.append(f"{indent}end\n")
                                i = nxt + 1
                                continue

                    pending_then_branch_probe = new_probe("branch", abs_line, "if_true")
                    chunk_out.append(raw)
                    i += 1
                    continue

                if _RE_CASE.match(stripped):
                    line_probe = new_probe("line", abs_line, "case")
                    chunk_out.append(emit_probe_stmt(indent_of(raw), line_probe))
                    chunk_out.append(raw)
                    case_depth += 1
                    i += 1
                    continue

                if case_depth > 0:
                    raw_no_nl = raw[:-1] if raw.endswith("\n") else raw
                    if "//" in raw_no_nl:
                        code_part, comment_part = raw_no_nl.split("//", 1)
                        comment_part = "//" + comment_part
                    else:
                        code_part, comment_part = raw_no_nl, ""

                    m_ci = re.match(r"^(\s*)(default|[^:]+?)\s*:\s*(.*)$", code_part)
                    if m_ci:
                        indent, label, rest = m_ci.group(1), m_ci.group(2), m_ci.group(3)
                        label_strip = label.strip()
                        if "=" not in label_strip and "[" not in label_strip and "]" not in label_strip:
                            rest_strip = rest.strip()
                            if rest_strip and not rest_strip.startswith("begin"):
                                br = new_probe("branch", abs_line, "case_item")
                                ln = new_probe("line", abs_line, "case_item_stmt")
                                chunk_out.append(f"{indent}{label_strip}: begin\n")
                                body_indent = child_indent(indent)
                                chunk_out.append(emit_probe_stmt(body_indent, br))
                                chunk_out.append(emit_probe_stmt(body_indent, ln))
                                chunk_out.append(f"{body_indent}{rest_strip} {comment_part}\n" if comment_part else f"{body_indent}{rest_strip}\n")
                                chunk_out.append(f"{indent}end\n")
                                i += 1
                                continue

                if _RE_CASE_ITEM.match(stripped):
                    probe_name = new_probe("branch", abs_line, "case_item")
                    if stripped.endswith("begin") or stripped.endswith("begin;") or " begin" in stripped:
                        chunk_out.append(raw)
                        chunk_out.append(emit_probe_stmt(child_indent(indent_of(raw)), probe_name))
                    else:
                        pending_case_item_probe = probe_name
                        chunk_out.append(raw)
                    i += 1
                    continue

                if pending_then_branch_probe is not None:
                    chunk_out.append(emit_probe_stmt(indent_of(raw), pending_then_branch_probe))
                    pending_then_branch_probe = None
                elif pending_else_branch_probe is not None:
                    chunk_out.append(emit_probe_stmt(indent_of(raw), pending_else_branch_probe))
                    pending_else_branch_probe = None
                elif pending_case_item_probe is not None:
                    chunk_out.append(emit_probe_stmt(indent_of(raw), pending_case_item_probe))
                    pending_case_item_probe = None

                if stripped and not _RE_ELSE.match(stripped) and not _RE_BEGIN.match(stripped) and not _RE_END.match(stripped):
                    if not _RE_CASE_ITEM.match(stripped):
                        line_probe = new_probe("line", abs_line, "stmt")
                        chunk_out.append(emit_probe_stmt(indent_of(raw), line_probe))

                chunk_out.append(raw)
                i += 1
                continue

            chunk_out.append(raw)
            i += 1

        decl_lines: list[str] = []
        if used_probe_names:
            decl_lines.extend([f"{mod_indent}reg {p};\n" for p in used_probe_names])
            decl_lines.append(f"{mod_indent}initial begin\n")
            for p in used_probe_names:
                decl_lines.append(f"{child_indent(mod_indent)}{p} = 1'b0;\n")
            decl_lines.append(f"{mod_indent}end\n")

        chunk_out = [ln if ln != "__COV_DECLS__\n" else "".join(decl_lines) for ln in chunk_out]
        return chunk_out, chunk_probes, probe_id

    out_lines: list[str] = []
    all_probes: list[Probe] = []
    probe_id = probe_start_id

    i = 0
    while i < len(src_lines):
        if _RE_MODULE.match(src_lines[i]):
            start = i
            j = i + 1
            while j < len(src_lines) and not _RE_ENDMODULE.match(src_lines[j]):
                j += 1
            if j >= len(src_lines):
                out_lines.append(src_lines[i])
                i += 1
                continue
            chunk = src_lines[start : j + 1]
            inst_chunk, chunk_probes, probe_id = instrument_module_chunk(chunk, start_line_no=start + 1, probe_id_in=probe_id)
            out_lines.extend(inst_chunk)
            all_probes.extend(chunk_probes)
            i = j + 1
            continue
        out_lines.append(src_lines[i])
        i += 1

    dst_path.write_text("".join(out_lines), encoding="utf-8", errors="replace")
    return all_probes, probe_id


def run_iverilog_and_vvp(
    *,
    repo_root: Path,
    tb_path: Path,
    rtl_paths: list[Path],
    out_vvp: Path,
) -> None:
    cmd_compile = ["iverilog", "-g2005-sv", "-o", str(out_vvp), str(tb_path)] + [str(p) for p in rtl_paths]
    cp = subprocess.run(cmd_compile, cwd=str(repo_root), capture_output=True, text=True)
    if cp.returncode != 0:
        sys.stderr.write(cp.stdout)
        sys.stderr.write(cp.stderr)
        raise RuntimeError("Falha compilando com iverilog")

    cmd_run = ["vvp", str(out_vvp)]
    rp = subprocess.run(cmd_run, cwd=str(repo_root), capture_output=True, text=True)
    sys.stdout.write(rp.stdout)
    sys.stderr.write(rp.stderr)
    if rp.returncode != 0:
        raise RuntimeError("Falha executando vvp")


def build_report(probes: list[Probe], probe_hit: set[str]) -> dict[str, object]:
    by_file: dict[str, dict[str, object]] = {}

    for p in probes:
        d = by_file.setdefault(
            p.file,
            {
                "lines_total": 0,
                "lines_hit": 0,
                "branches_total": 0,
                "branches_hit": 0,
                "uncovered_lines": [],
                "uncovered_branches": [],
            },
        )
        is_hit = p.name in probe_hit
        if p.kind == "line":
            d["lines_total"] += 1
            if is_hit:
                d["lines_hit"] += 1
            else:
                d["uncovered_lines"].append({"line": p.line, "detail": p.detail, "probe": p.name})
        else:
            d["branches_total"] += 1
            if is_hit:
                d["branches_hit"] += 1
            else:
                d["uncovered_branches"].append({"line": p.line, "detail": p.detail, "probe": p.name})

    return {"files": by_file}


def _pct(a: int, b: int) -> str:
    if b == 0:
        return "n/a"
    return f"{(100.0 * a / b):.2f}%"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description="Line/branch coverage por instrumentação RTL + VCD (sem Verilator).",
    )
    ap.add_argument("--tb", default=str(Path("tb") / "tb_mips_top.v"), help="Arquivo do testbench")
    ap.add_argument("--rtl-dir", default=str(Path("rtl")), help="Diretório com RTL (.v)")
    ap.add_argument("--vcd", default="tb_mips_top.vcd", help="VCD gerado pelo testbench")
    ap.add_argument("--no-run", action="store_true", help="Não roda simulação, só analisa o VCD")
    ap.add_argument("--json", default="", help="Grava relatório JSON em arquivo")
    ap.add_argument("--top-uncovered", type=int, default=50, help="Máximo de itens uncovered por arquivo")
    ap.add_argument("--work", default="", help="Diretório de trabalho (mantém RTL instrumentado)")
    args = ap.parse_args(argv)

    repo_root = Path(__file__).resolve().parent
    tb_path = (repo_root / args.tb).resolve()
    rtl_dir = (repo_root / args.rtl_dir).resolve()
    vcd_path = (repo_root / args.vcd).resolve()

    rtl_files = sorted([p for p in rtl_dir.glob("*.v") if p.is_file()])
    if not rtl_files:
        print(f"Nenhum .v encontrado em {rtl_dir}", file=sys.stderr)
        return 2
    if not tb_path.exists():
        print(f"Testbench não encontrado: {tb_path}", file=sys.stderr)
        return 2

    all_probes: list[Probe] = []
    probe_id = 0

    def run_in_workdir(work: Path) -> int:
        nonlocal probe_id, all_probes
        inst_rtl_dir = work / "rtl"
        inst_rtl_dir.mkdir(parents=True, exist_ok=True)

        inst_rtl_files: list[Path] = []
        for src in rtl_files:
            dst = inst_rtl_dir / src.name
            p, probe_id = instrument_verilog_file(src, dst, probe_start_id=probe_id)
            all_probes.extend(p)
            inst_rtl_files.append(dst)

        out_vvp = work / "cov_tb.vvp"

        if not args.no_run:
            run_iverilog_and_vvp(repo_root=repo_root, tb_path=tb_path, rtl_paths=inst_rtl_files, out_vvp=out_vvp)

        if not vcd_path.exists():
            print(f"VCD não encontrado: {vcd_path}", file=sys.stderr)
            return 2

        vcd_defs = parse_vcd_definitions(vcd_path)
        probe_name_set = {p.name for p in all_probes}

        probe_code_by_name: dict[str, str] = {}
        for code, vv in vcd_defs.items():
            leaf = vv.name.split(".")[-1]
            if leaf in probe_name_set:
                probe_code_by_name[leaf] = code

        missing = sorted(probe_name_set - set(probe_code_by_name.keys()))
        if missing:
            print(f"Aviso: {len(missing)} probes não encontrados no VCD (dumpvars limitado?)", file=sys.stderr)

        target_codes = set(probe_code_by_name.values())
        hit_codes = parse_vcd_scalar_ones(vcd_path, target_codes)
        hit_probe_names = {name for name, code in probe_code_by_name.items() if code in hit_codes}

        report = build_report(all_probes, hit_probe_names)

        files: dict[str, dict[str, object]] = report["files"]  # type: ignore[assignment]

        print("=================================================================")
        print("RTL line/branch coverage (instrumentado + VCD)")
        print("=================================================================")
        for file_path, agg in sorted(files.items(), key=lambda kv: kv[0]):
            lt = int(agg["lines_total"])
            lh = int(agg["lines_hit"])
            bt = int(agg["branches_total"])
            bh = int(agg["branches_hit"])
            print(f"- {Path(file_path).name}: lines {lh}/{lt} ({_pct(lh, lt)}), branches {bh}/{bt} ({_pct(bh, bt)})")

        print("")
        print("Uncovered (por arquivo):")
        for file_path, agg in sorted(files.items(), key=lambda kv: kv[0]):
            uls = list(agg["uncovered_lines"])
            ubs = list(agg["uncovered_branches"])
            if not uls and not ubs:
                continue
            print(f"- {Path(file_path).name}")
            for item in uls[: args.top_uncovered]:
                print(f"  line {item['line']}: {item['detail']}")
            for item in ubs[: args.top_uncovered]:
                print(f"  branch line {item['line']}: {item['detail']}")

        if args.json:
            out_json = (repo_root / args.json).resolve()
            out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
        return 0

    if args.work:
        work = (repo_root / args.work).resolve()
        work.mkdir(parents=True, exist_ok=True)
        return run_in_workdir(work)

    with tempfile.TemporaryDirectory(prefix="mips_cov_") as td:
        return run_in_workdir(Path(td))


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

