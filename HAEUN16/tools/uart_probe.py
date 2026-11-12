#!/usr/bin/env python3
"""COM 포트 UART RX/TX 프로브 — 키 한 글자 보내고 에코 확인."""
import argparse
import sys
import time

try:
    import serial
except ImportError:
    print("pip install pyserial")
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser(description="UART echo probe (115200 8N1)")
    ap.add_argument("port", help="COM port, e.g. COM7")
    ap.add_argument(
        "--byte",
        default="x",
        help="byte to send (default: x)",
    )
    ap.add_argument(
        "--timeout",
        type=float,
        default=2.0,
        help="seconds to wait for echo",
    )
    args = ap.parse_args()

    data = args.byte.encode("ascii", errors="replace")[:1]
    if not data:
        print("empty byte")
        sys.exit(1)

    with serial.Serial(args.port, 115200, timeout=0.1) as ser:
        ser.dtr = False
        ser.rts = False
        ser.reset_input_buffer()
        ser.write(data)
        ser.flush()
        deadline = time.monotonic() + args.timeout
        got = b""
        while time.monotonic() < deadline:
            chunk = ser.read(1)
            if chunk:
                got += chunk
                if got == data:
                    print(f"PASS: sent {data!r}, echo {got!r}")
                    return
        print(f"FAIL: sent {data!r}, got {got!r} (timeout {args.timeout}s)")
        print("  -> pin38 <- dongle TX, GND common, or try top_uart_rx_echo bitstream")
        sys.exit(1)


if __name__ == "__main__":
    main()
