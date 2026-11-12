#!/usr/bin/env python3
"""USB-TTL 동글만 루프백 테스트 (FPGA 없이).

동글 TX 핀과 RX 핀을 점퍼 한 줄로 서로 연결한 뒤:
  python tools/uart_dongle_loopback.py COM7

키 입력이 에코되면 동글+COM+드라이버는 정상.
"""
import sys
import time

try:
    import serial
except ImportError:
    print("pip install pyserial")
    sys.exit(1)

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM7"
TEST = b"loopback_ok\r\n"


def main() -> int:
    print(f"=== 동글 루프백 {PORT} ===")
    print("동글 TX ↔ RX 를 점퍼 한 줄로 연결하세요 (FPGA 선은 모두 떼기).\n")
    try:
        ser = serial.Serial(PORT, 115200, timeout=1.0)
        ser.dtr = False
        ser.rts = False
    except serial.SerialException as e:
        print(f"OPEN FAIL: {e}")
        return 1

    ser.reset_input_buffer()
    ser.write(TEST)
    time.sleep(0.2)
    got = ser.read(64)
    ser.close()

    if TEST in got or got == TEST.strip():
        print(f"PASS: 에코 수신 {got!r}")
        print("→ 동글/COM7은 정상. 문제는 Tang 37/38 배선 또는 핀 번호.")
        return 0

    print(f"FAIL: 보냄 {TEST!r}  받음 {got!r}")
    print("→ 동글 불량, COM 틀림, 또는 TX-RX 루프백 선 미연결.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
