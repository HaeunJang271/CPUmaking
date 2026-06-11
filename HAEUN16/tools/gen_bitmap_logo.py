#!/usr/bin/env python3
"""PNG -> svo_bitmap_logo_rom.vh (localparam flat ROM, Gowin-safe — no initial)."""
from __future__ import annotations

import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    raise SystemExit("pip install pillow") from e

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PNG = ROOT / "assets" / "haeun_os_logo.png"
OUT = ROOT / "hdmi_colorbars" / "src" / "hdmi" / "svo_bitmap_logo_rom.vh"


def crop_foreground(img: Image.Image, threshold: int = 32) -> Image.Image:
    gray = img.convert("L")
    w, h = gray.size
    px = gray.load()
    bbox = None
    for y in range(h):
        for x in range(w):
            if px[x, y] > threshold:
                if bbox is None:
                    bbox = [x, y, x, y]
                else:
                    bbox[0] = min(bbox[0], x)
                    bbox[1] = min(bbox[1], y)
                    bbox[2] = max(bbox[2], x)
                    bbox[3] = max(bbox[3], y)
    if bbox is None:
        return gray
    return gray.crop(tuple(bbox))


def pack_rows(bits: list[list[int]]) -> tuple[list[int], int, int]:
    h = len(bits)
    w = len(bits[0]) if h else 0
    row_bytes = (w + 7) // 8
    rom: list[int] = []
    for row in bits:
        for byte_i in range(row_bytes):
            val = 0
            for bit in range(8):
                x = byte_i * 8 + bit
                if x < w and row[x]:
                    val |= 1 << (7 - bit)
            rom.append(val)
    return rom, w, h


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--png", type=Path, default=DEFAULT_PNG)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--threshold", type=int, default=32)
    ap.add_argument("--scale", type=float, default=0.75, help="logo scale (default 0.75)")
    ap.add_argument("--y0", type=int, default=20)
    args = ap.parse_args()

    img = Image.open(args.png)
    cropped = crop_foreground(img, args.threshold)
    if args.scale != 1.0:
        w0, h0 = cropped.size
        nw = max(1, int(w0 * args.scale))
        nh = max(1, int(h0 * args.scale))
        cropped = cropped.resize((nw, nh), Image.Resampling.NEAREST)
    w, h = cropped.size
    px = cropped.load()
    bits = [[px[x, y] > args.threshold for x in range(w)] for y in range(h)]
    rom, w, h = pack_rows(bits)
    row_bytes = (w + 7) // 8
    x0 = (640 - w) // 2
    nbits = len(rom) * 8

    # MSB=high addr, LSB=addr0 (logo_rom_flat[addr*8 +: 8])
    flat = ", ".join(f"8'h{b:02X}" for b in reversed(rom))

    lines = [
        "// svo_bitmap_logo_rom.vh - HAEUN-OS bitmap logo (generated, no initial)",
        "// .gprj 에 등록하지 말 것 — svo_bitmap_logo.v module 안에서만 include",
        f"localparam LOGO_W = 10'd{w};",
        f"localparam LOGO_H = 10'd{h};",
        f"localparam LOGO_X0 = 10'd{x0};",
        f"localparam LOGO_Y0 = 10'd{args.y0};",
        f"localparam LOGO_ROW_BYTES = 8'd{row_bytes};",
        f"localparam LOGO_ROM_BYTES = 12'd{len(rom)};",
        f"localparam LOGO_ROM_ABITS = 12;",
        f"localparam [{nbits - 1}:0] logo_rom_flat = {{",
        f"  {flat}",
        "};",
    ]

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {args.out}")
    print(f"  size {w}x{h} @ ({x0},{args.y0}), rom={len(rom)} bytes ({nbits} bits)")


if __name__ == "__main__":
    main()
