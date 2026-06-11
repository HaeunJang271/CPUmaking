#!/usr/bin/env python3
"""Capture UART around S1 reset; compare streams and scan baud rates.

Usage:
  1. Close miniterm / other programs using the COM port.
  2. python tools/uart_reset_sniff.py COM5
  3. Press S1 when prompted.
"""
import sys
import time

try:
    import serial
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM5"
BAUDS = [115200, 57600, 230400, 9600, 460800, 38400, 1000000]


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


def read_for(ser, seconds):
    buf = b""
    t0 = time.time()
    while time.time() - t0 < seconds:
        buf += ser.read(512)
    return buf


def hex_preview(buf, n=64):
    if not buf:
        return "(empty)"
    return " ".join(f"{b:02X}" for b in buf[:n])


def main():
    print(f"=== UART reset sniff on {PORT} ===\n")
    print("Close miniterm first (Ctrl+]).")
    print("Baseline 2s, then press S1 within the next 3s.\n")

    try:
        ser = serial.Serial(PORT, 115200, timeout=0.15)
    except serial.SerialException as e:
        print(f"OPEN FAIL: {e}")
        print("Another program (miniterm) may be using the port.")
        return 1

    before = read_for(ser, 2.0)
    print(f"Before S1: {len(before)} bytes")
    print(f"  hex: {hex_preview(before)}")

    print("\n>>> Press S1 NOW <<<")
    after = read_for(ser, 3.0)
    ser.close()

    print(f"\nAfter S1:  {len(after)} bytes")
    print(f"  hex: {hex_preview(after)}")

    if b"HAEUN" in after:
        print("\n*** Found HAEUN in post-reset stream at 115200 ***")
        text = after.decode("utf-8", errors="replace")
        print(text[:300])
        return 0

    if len(before) == len(after) and before == after:
        print("\nStreams identical - FPGA UART may not be connected to this port,")
        print("or the bitstream on the board is not HAEUN16 (Program Device again).")
    elif abs(len(after) - len(before)) < 20:
        print("\nByte count barely changed - S1 may not reset CPU, or baud is wrong")
        print("(garbage looks the same before/after).")
    else:
        print(f"\nByte count changed ({len(before)} -> {len(after)}) - reset likely fired,")
        print("but 115200 decode is wrong. Scanning baud rates...\n")

    print("Scan baud (press S1 once at start of scan):\n")
    best = (0, 0, b"")
    for b in BAUDS:
        try:
            ser = serial.Serial(PORT, b, timeout=0.15)
        except serial.SerialException as e:
            print(f"  {b:7d}: open fail - {e}")
            continue
        buf = read_for(ser, 2.5)
        ser.close()
        sc = score(buf)
        mark = " ***" if sc >= 50 else ""
        print(f"  {b:7d}: {len(buf):5d} bytes, score={sc}{mark}")
        if sc > best[0]:
            best = (sc, b, buf)

    if best[0] >= 50:
        print(f"\n*** Try miniterm at {best[1]} baud ***")
        print(best[2].decode("utf-8", errors="replace")[:200])
    else:
        print("\nNo boot string at any baud.")
        print("Checklist:")
        print("  1. Gowin -> Program Device -> HAEUN16_9K.fs (uart_tx on pin 17)")
        print("  2. S1: LEDs blink then all 6 ON (CPU boot OK)")
        print("  3. Close Gowin completely, unplug/replug USB (BL702 UART recovery)")
        print("  4. Use the higher COM (UART), not the lower one (JTAG)")
        print("  5. Try top_uart_smoke (UART_TX.md) to isolate pin 17 path")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
