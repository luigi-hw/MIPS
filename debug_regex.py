
import re

_RE_CASE = re.compile(r"^\s*case(z|x)?\s*\(")
_RE_CASE_ITEM = re.compile(r"^\s*(default\s*:|[^:\s][^:]*:)\s*(begin\b)?\s*$")

lines = [
    "		`ADD  : pre_out = rega + regb; //0",
    "		`SRA  : pre_out = $signed(rega) >>> regb; //12",
    "case (control)"
]

def test():
    print(f"CASE match 'case (control)': {_RE_CASE.match('case (control)')}")
    
    for l in lines[:2]:
        stripped = l.strip()
        print(f"Line: {l}")
        
        # Test Case Item Strict
        print(f"  Strict match: {_RE_CASE_ITEM.match(stripped)}")
        
        # Test Case Item Inline Logic
        raw = l
        raw_no_nl = raw
        if "//" in raw_no_nl:
            code_part, comment_part = raw_no_nl.split("//", 1)
        else:
            code_part, comment_part = raw_no_nl, ""
            
        m_ci = re.match(r"^(\s*)(default|[^:]+?)\s*:\s*(.*)$", code_part)
        print(f"  Inline match: {m_ci}")
        if m_ci:
            print(f"    Groups: {m_ci.groups()}")

test()
