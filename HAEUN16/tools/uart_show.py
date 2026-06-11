#!/usr/bin/env python3
"""Show UART bytes; separate BL702 banner from post-S1 FPGA data.

Usage:
  python tools/uart_show.py COM7
  python tools/uart_show.py COM6
"""
import sys
import time

try:
    import serial
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM7"
BAUD = int(sys.argv[2]) if len(sys.argv) > 2 else 115200

BL702_MARKERS = (b"Lichee", b"Toggle led", b"Command>", b"On Lichee")


def show(label: str, buf: bytes) -> None:
    print(f"\n[{label}] {len(buf)} bytes")
    if not buf:
        print("  (empty)")
        return
    print("  hex:", " ".join(f"{b:02X}" for b in buf[:64]))
    if len(buf) > 64:
        print("       ...")
    text = "".join(chr(b) if 32 <= b < 127 or b in (10, 13) else "." for b in buf)
    print("  txt:", text[:180].replace("\r", ""))


def score(buf: bytes) -> int:
    if b"HAEUN" in buf:
        return 100
    if b"UART_OK" in buf:
        return 90
    if b"Boot" in buf:
        return 50
    return 0


def main() -> int:
    print(f"=== UART show {PORT} @ {BAUD} ===")
    print("Close miniterm / Gowin first.\n")
    try:
        ser = serial.Serial(PORT, BAUD, timeout=0.2)
        ser.dtr = False
        ser.rts = False
    except serial.SerialException as e:
        print(f"OPEN FAIL: {e}")
        return 1

    print("Draining BL702 banner (1.5s)...")
    banner = b""
    t0 = time.time()
    while time.time() - t0 < 1.5:
        banner += ser.read(512)

    print(">>> Press S1 NOW (wait ~3s for BL702 boot delay) <<<")
    after = b""
    t0 = time.time()
    while time.time() - t0 < 6.0:
        after += ser.read(512)
    ser.close()

    show("BL702 on open", banner)
    show("After S1", after)

    sc = score(after)
    if sc >= 50:
        print("\n*** FPGA UART OK ***")
    elif any(m in (banner + after) for m in BL702_MARKERS) or b"____" in after:
        print("\n*** BL702 Lichee menu only - FPGA UART blocked ***")
        print("FPGA Program OK. Next: flash BL702 usb2uartjtag (1 time):")
        print("  powershell -File tools\\flash_bl702.ps1 -Help")
    elif len(after) == 0 and len(banner) == 0:
        print("\nNo data on this COM. Wrong port?")
    else:
        print("\nBytes after S1 but no HAEUN/UART_OK. Re-Program latest .fs.")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
