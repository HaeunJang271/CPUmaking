#!/usr/bin/env python3
"""Listen for FPGA UART (filters BL702 banner noise).

Usage:
  1. Close miniterm (port must be free).
  2. python tools/uart_listen.py COM7
  3. Press S1 on the board when prompted.
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


def main():
    print(f"=== FPGA UART listen on {PORT} @ {BAUD} ===\n")
    try:
        ser = serial.Serial(PORT, BAUD, timeout=0.2)
    except serial.SerialException as e:
        print(f"OPEN FAIL: {e}")
        return 1

    # DTR/RTS off — some adapters misbehave with defaults
    ser.dtr = False
    ser.rts = False

    print("Listening 3s (BL702 menu may appear)...")
    buf = b""
    t0 = time.time()
    while time.time() - t0 < 3.0:
        buf += ser.read(512)

    print(f"Before S1: {len(buf)} bytes")
    if buf:
        print(buf.decode("utf-8", errors="replace")[-400:])

    print("\n>>> Press S1 NOW (hold ~0.5s) <<<")
    after = b""
    t0 = time.time()
    while time.time() - t0 < 5.0:
        chunk = ser.read(512)
        if chunk:
            after += chunk
            text = chunk.decode("utf-8", errors="replace")
            print(text, end="", flush=True)

    ser.close()

    if b"HAEUN" in after:
        print("\n\n*** HAEUN-16 Boot detected ***")
    elif b"UART_OK" in after:
        print("\n\n*** UART smoke OK ***")
    elif b">" in after and len(after) > 20:
        print("\n\n*** Prompt bytes seen (check baud) ***")
    elif len(after) == 0:
        print("\nNo new bytes after S1.")
        print("Check: pin 17 Program done? top_tangnano9k? USB replug?")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
