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
    print("S1 리셋 → 2.5초 BL702 대기 → 10초 수신 (115200).\n")

    try:
        ser = serial.Serial(PORT, 115200, timeout=0.15)
        ser.dtr = False
        ser.rts = False
    except serial.SerialException as e:
        print(f"OPEN FAIL: {e}")
        print("Another program (miniterm) may be using the port.")
        return 1

    ser.reset_input_buffer()
    print(">>> Press S1 NOW <<<")
    glitch = read_for(ser, 0.5)
    print("BL702 hold 2.5s...")
    time.sleep(2.5)
    boot = read_for(ser, 10.0)
    ser.close()

    print(f"\nReset glitch (0.5s): {len(glitch)} bytes")
    print(f"  hex: {hex_preview(glitch)}")
    print(f"After BL702 (10s):   {len(boot)} bytes")
    print(f"  hex: {hex_preview(boot)}")
    if boot:
        print(f"  txt: {boot[:120].decode('ascii', errors='replace')!r}")

    if b"HAEUN" in boot:
        print("\n*** HAEUN-OS boot at 115200 ***")
        print(boot.decode("utf-8", errors="replace")[:300])
        return 0

    if len(glitch) > 0 and len(boot) == 0:
        print(
            "\n리셋 직후 짧은 깨진 바이트만 있고 부트 없음."
            "\n→ pin37 배선/GND 또는 ext_uart Program(-ExtUart) 점검."
        )
    elif len(boot) > 0 and b"HAEUN" not in boot:
        print("\n뭔가 왔지만 HAEUN-OS 아님 → gen_ram + Program 또는 보드레이트 스캔.")
    else:
        print("\n부트 UART 무신호 → 배선·Program·top_haeun16_soc 확인.")

    print("\nScan baud (S1 once at start of scan):\n")
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
        print("Checklist (외부 FT232 → pin 37/38):")
        print("  1. pwsh -File tools\\sync_soc_gowin.ps1 -ExtUart → Gowin Program (top_haeun16_soc)")
        print("  2. 배선: FPGA37→동글RX, FPGA38←동글TX, GND")
        print("  3. S1 후 LED 6개 ON + HDMI READY → CPU OK, UART만 점검")
        print("  4. COM7=FT232(0403:6001), miniterm/Gowin 종료 후 테스트")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
