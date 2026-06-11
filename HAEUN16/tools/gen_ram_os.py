#!/usr/bin/env python3
"""os.asm -> ram_fpga.v initial block 갱신"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASM = ROOT / "tools" / "asm.py"
OS = ROOT / "programs" / "os.asm"
RAM = ROOT / "ram_fpga.v"


def main():
    out = subprocess.check_output(
        [sys.executable, str(ASM), str(OS), "--verilog"], text=True
    )
    mem_lines = [l.strip() for l in out.splitlines() if l.strip().startswith("memory[")]
    text = RAM.read_text(encoding="utf-8")
    header = (
        "// 프로그램: os.asm (HAEUN-OS v0.1 HDMI) — "
        "갱신: python tools/gen_ram_os.py\n"
    )
    text = re.sub(r"// 프로그램:.*\n", header, text, count=1)
    init = (
        "    initial begin\n"
        "        for (i = 0; i < 512; i = i + 1)\n"
        "            memory[i] = 16'h0000;\n"
        + "\n".join("        " + l for l in mem_lines)
        + "\n    end"
    )
    text = re.sub(
        r"    initial begin.*?    end\n\n    always @",
        init + "\n\n    always @",
        text,
        flags=re.S,
    )
    RAM.write_text(text, encoding="utf-8")
    print(f"Updated {RAM.name} ({len(mem_lines)} words)")


if __name__ == "__main__":
    main()
