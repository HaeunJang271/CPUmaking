#!/usr/bin/env python3
"""Generate svo_ascii_logo_rom.vh — HAEUN-OS /|\\ block banner (2x scale on FPGA)."""
from pathlib import Path

# 34 cols — 글자 6칸 + 간격 1칸, /|\\·_ 획만 (640px에서 2x 스케일 중앙 정렬)
ART = [
    "|    |  /\\    |___|  |   |  |\\  |",
    "|    | /  \\   |___   |   |  | \\ |",
    "|/\\\\| | /__\\  |___   |   |  |  \\|",
    "|  | |    |      |    |   |  |   |",
    "|  | |    |      |    |   |  |   |",
    "|  | |    |   ___|    |___|  |   |",
    "      ___    / _ \\              ",
    "     ( _ )  | (_) |             ",
    "      ___    \\___/              ",
]

WIDTH = 34
OUT = Path(__file__).resolve().parents[1] / "hdmi_colorbars/src/hdmi/svo_ascii_logo_rom.vh"


def main() -> None:
    lines = [" " * WIDTH] + ART  # 상단 여백 1줄 (16px @2x)
    normed = []
    for i, line in enumerate(lines):
        if len(line) < WIDTH:
            line = line + (" " * (WIDTH - len(line)))
        elif len(line) > WIDTH:
            raise SystemExit(f"line {i} len {len(line)} > {WIDTH}: {line!r}")
        normed.append(line)

    idx = 0
    parts = [
        "// svo_ascii_logo_rom.vh - HAEUN-OS /|\\ ASCII banner",
        f"localparam LOGO_COLS = 8'd{WIDTH};",
        f"localparam LOGO_ROWS = 8'd{len(normed)};",
        "localparam MEM_ABITS = 9;",
        f"localparam MSG_STOP  = 9'd{sum(WIDTH + 1 for _ in normed)};",
        "reg [7:0] msg_rom [0:511];",
        "initial begin",
    ]
    for line in normed:
        parts.append(f"  // {line}")
        for ch in line:
            parts.append(f"  msg_rom[{idx}] = 8'd{ord(ch)};")
            idx += 1
        parts.append(f"  msg_rom[{idx}] = 8'd10;")
        idx += 1
    parts.append("end")
    OUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({idx} bytes, {len(normed)} lines)")
    print("Preview:")
    for line in normed:
        print(line)


if __name__ == "__main__":
    main()
