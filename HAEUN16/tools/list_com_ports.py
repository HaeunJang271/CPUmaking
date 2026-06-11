#!/usr/bin/env python3
"""List Windows COM ports and mark Tang Nano 9K JTAG vs UART.

Usage:
  python tools/list_com_ports.py
"""
from __future__ import annotations

import sys

try:
    from serial.tools import list_ports
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)


def classify(desc: str, hwid: str) -> str:
    blob = f"{desc} {hwid}".upper()
    if "BTHENUM" in blob or "BLUETOOTH" in blob:
        return "Bluetooth - BL702 플래시 불가"
    if "FACTORYAIOT_PROG" in blob or "PID_6010" in blob:
        return "JTAG (Gowin Programmer) - 키보드 입력 불가"
    if "CDC" in blob or "USBMODEM" in blob or "ACM" in blob:
        return "BL702 DFU/UART 후보 (플래시/터미널용)"
    if "BL702" in blob or "BOUFFALO" in blob or "BLDEV" in blob:
        return "BL702 DFU/UART 후보 (플래시/터미널용)"
    if "CH340" in blob or "CP210" in blob:
        return "외부 USB-TTL (터미널용)"
    return "기타 USB Serial"


def main() -> int:
    print("=== Tang Nano 9K COM 진단 ===\n")
    ports = list(list_ports.comports())
    if not ports:
        print("COM 포트를 찾지 못했습니다. USB 연결 후 다시 실행하세요.")
        return 1

    uart_like = 0
    jtag = 0
    for p in sorted(ports, key=lambda x: int(x.device.replace("COM", ""))):
        kind = classify(p.description, p.hwid)
        if "JTAG" in kind:
            jtag += 1
        if "UART" in kind or "CDC" in kind:
            uart_like += 1
        print(f"{p.device:6}  {kind}")
        print(f"       {p.description}")
        if p.hwid:
            print(f"       {p.hwid[:90]}{'...' if len(p.hwid) > 90 else ''}")

    print()
    if jtag and not uart_like:
        print("*** 지금 상태: JTAG(COM6 등)만 보임 → PC 키보드 입력 경로 없음 ***")
        print()
        print("COM6 miniterm은 JTAG 바이너리라 깨진 글자만 나옵니다.")
        print("키보드 입력은 아래 중 하나가 필요합니다:")
        print()
        print("  A) BL702 usb2uartjtag 플래시 (1회, 온보드 USB UART 복구)")
        print("     powershell -File tools\\flash_bl702.ps1 -Help")
        print("     펌웨어: HAEUN16\\usb2uartjtag_bl702.bin")
        print()
        print("  B) 외부 USB-TTL 3.3V + 헤더 핀 (가장 확실)")
        print("     pin 37 (FPGA TX) → 동글 RX")
        print("     pin 38 (FPGA RX) ← 동글 TX")
        print("     GND 공통")
        print("     Gowin: soc/tangnano9k_soc_ext_uart.cst 사용 후 재 Program")
        print("     PC: 동글 COM 포트, 115200")
    elif uart_like:
        print("UART 후보 COM이 있습니다. Gowin 종료 후:")
        print("  python tools\\uart_show.py <UART_COM>")
        print("  python -m serial.tools.miniterm <UART_COM> 115200")
    else:
        print("Tang Nano USB Serial이 안 보입니다. 케이블·USB 포트를 확인하세요.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
