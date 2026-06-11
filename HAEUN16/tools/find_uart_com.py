#!/usr/bin/env python3
"""Scan COM ports for HAEUN-16 boot UART output. Usage: python tools/find_uart_com.py"""

import sys
import time

try:
    import serial
    import serial.tools.list_ports as lp
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)

SKIP_DESC = ("bluetooth", "블루투스")


def is_candidate(port):
    d = (port.description or "").lower()
    if any(s in d for s in SKIP_DESC):
        return False
    return True


def probe(port_name, seconds=4):
    try:
        ser = serial.Serial(port_name, 115200, timeout=0.2)
    except serial.SerialException as e:
        return None, str(e)
    buf = b""
    t0 = time.time()
    while time.time() - t0 < seconds:
        buf += ser.read(512)
    ser.close()
    return buf, None


def main():
    ports = [p for p in lp.comports() if is_candidate(p)]
    if not ports:
        print("No USB serial ports (Bluetooth excluded).")
        print("Plug Tang Nano 9K USB and check Device Manager.")
        return

    print("=== USB serial ports (not Bluetooth) ===")
    for p in ports:
        print(f"  {p.device}: {p.description} (VID={p.vid:#06x} PID={p.pid:#06x})")

    print("\n>>> Reset Tang Nano 9K (S1) within the next few seconds...\n")

    best = None
    for p in ports:
        data, err = probe(p.device)
        if err:
            print(f"{p.device}: OPEN FAIL - {err}")
            continue
        text = data.decode("utf-8", errors="replace")
        score = 0
        if b"HAEUN" in data:
            score += 100
        if b"Boot" in data:
            score += 50
        if b">" in data:
            score += 10
        printable = sum(32 <= c < 127 or c in (10, 13) for c in data)
        print(f"{p.device}: {len(data)} bytes, printable={printable}, score={score}")
        if data:
            preview = repr(data[:80])
            print(f"  preview: {preview}")
        if best is None or score > best[0]:
            best = (score, p.device, text)

    print()
    if best and best[0] > 0:
        print(f"*** USE: {best[1]}  (115200 8N1) ***")
        print(f"    python -m serial.tools.miniterm {best[1]} 115200")
    elif ports:
        likely = ports[0].device
        for p in ports:
            if p.vid == 0x0403:
                likely = p.device
        print(f"No boot string yet. Most likely Tang Nano UART: {likely}")
        print("  1. Device Manager -> USB Serial Converter B -> Advanced -> Load VCP")
        print("  2. Re-Program HAEUN16_9K.fs (uart_fifo_tx.v included)")
        print(f"  3. python -m serial.tools.miniterm {likely} 115200")
        print("  4. Press S1 reset while miniterm is open")
    print("\nDo NOT use COM11-COM18 (Bluetooth).")


if __name__ == "__main__":
    main()
