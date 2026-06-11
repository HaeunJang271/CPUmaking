#!/usr/bin/env python3
"""Scan baud rates for HAEUN-16 boot string (close miniterm first).

Usage:
  python tools/uart_try_baud.py COM7
  Press S1 once when the first baud line appears.
"""
import sys
import time

try:
    import serial
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM7"
BAUDS = [
    115200, 230400, 57600, 460800, 38400, 9600, 1000000,
    122880, 111111, 125000, 250000, 500000,
]


def score(buf: bytes) -> int:
    s = 0
    if b"HAEUN" in buf:
        s += 100
    if b"Boot" in buf:
        s += 50
    if b">" in buf:
        s += 10
    s += sum(32 <= c < 127 or c in (10, 13) for c in buf) // 4
    return s


print(f"=== Baud scan on {PORT} ===")
print("Close miniterm. Press S1 once when scanning starts.\n")

best = (0, 0, b"")
for i, b in enumerate(BAUDS):
    try:
        ser = serial.Serial(PORT, b, timeout=0.15)
        ser.dtr = False
        ser.rts = False
    except serial.SerialException as e:
        print(f"{b:7d}: open failed - {e}")
        continue
    if i == 0:
        print(">>> Press S1 NOW <<<")
    buf = b""
    t0 = time.time()
    while time.time() - t0 < 2.0:
        buf += ser.read(512)
    ser.close()
    sc = score(buf)
    mark = " ***" if sc >= 50 else ""
    print(f"{b:7d}: {len(buf):5d} bytes, score={sc}{mark}")
    if sc > best[0]:
        best = (sc, b, buf)

if best[0] >= 50:
    print(f"\n*** Use miniterm at {best[1]} baud ***")
    text = best[2].decode("ascii", errors="replace")[:300]
    print(text)
else:
    print("\nNo clean boot string at any baud.")
    print("Try: pin 17 Program, USB replug, COM7 (not COM6).")
