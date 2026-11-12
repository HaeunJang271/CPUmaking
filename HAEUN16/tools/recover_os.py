#!/usr/bin/env python3
"""HAEUN-OS UART 복구 진단 — COM 수신 / 보드레이트 스캔."""
import argparse
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

BAUDS = [115200, 57600, 230400, 9600, 38400, 460800]


def open_port(port: str, baud: int):
    import serial

    ser = serial.Serial(port, baud, timeout=0.25)
    ser.dtr = False
    ser.rts = False
    return ser


def listen(port: str, baud: int, seconds: float) -> bytes:
    ser = open_port(port, baud)
    ser.reset_input_buffer()
    print(f"\n[{baud} baud] {seconds:.0f}초 대기 — 지금 보드 S1 리셋!")
    deadline = time.monotonic() + seconds
    buf = b""
    while time.monotonic() < deadline:
        chunk = ser.read(512)
        if chunk:
            buf += chunk
            print(f"  +{len(chunk)} bytes (누적 {len(buf)})")
    ser.close()
    return buf


def score(buf: bytes) -> int:
    s = 0
    if b"HAEUN" in buf:
        s += 100
    if b">" in buf:
        s += 20
    s += sum(32 <= c < 127 or c in (10, 13) for c in buf) // 3
    return s


def show_buf(buf: bytes) -> None:
    if not buf:
        print("  (수신 없음)")
        return
    text = buf.decode("ascii", errors="replace")
    print(f"  hex: {buf[:48].hex()}")
    print(f"  txt: {repr(text[:100])}")


def uart_test(port: str, baud: int, seconds: float) -> bool:
    try:
        buf = listen(port, baud, seconds)
    except Exception as e:
        print(f"FAIL: {e}")
        return False

    show_buf(buf)
    if b"HAEUN" in buf:
        print("\nPASS: HAEUN-OS 부트 문자열 수신")
        return True
    if len(buf) > 0:
        print("\nWARN: 뭔가 왔지만 HAEUN-OS 아님 (보드레이트/비트스트림 점검)")
        return False
    print("\nFAIL: 0바이트 — 아래 확인")
    print("  1) Tang USB-C 전원 LED")
    print("  2) Gowin Program 성공 (top_haeun16_soc, ext_uart pin37/38)")
    print("  3) 배선: FPGA37→동글RX, FPGA38←동글TX, GND")
    print("  4) COM7=FT232(0403:6001), COM6=JTAG 아님")
    return False


def baud_scan(port: str) -> None:
    print(f"=== 보드레이트 스캔 {port} ===")
    print("첫 줄 나오면 S1 리셋\n")
    best = (0, 0, b"")
    for i, b in enumerate(BAUDS):
        try:
            buf = listen(port, b, 2.5)
        except Exception as e:
            print(f"  open fail: {e}")
            continue
        sc = score(buf)
        mark = " ***" if sc >= 50 else ""
        print(f"  score={sc}, len={len(buf)}{mark}")
        if sc > best[0]:
            best = (sc, b, buf)
    print()
    if best[0] >= 50:
        print(f"*** miniterm {best[1]} baud 사용 ***")
        show_buf(best[2])
    else:
        print("모든 보드레이트에서 HAEUN 없음 → Program/배선 문제")


def run_sync(ext_uart: bool) -> int:
    ps1 = ROOT / "tools" / "sync_soc_gowin.ps1"
    args = ["pwsh", "-File", str(ps1)]
    if ext_uart:
        args.append("-ExtUart")
    print(">>", " ".join(args))
    return subprocess.call(args, cwd=str(ROOT))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sync", action="store_true")
    ap.add_argument("--test", metavar="COM", help="UART 수신 테스트 (기본 COM7)")
    ap.add_argument("--scan", metavar="COM", help="보드레이트 스캔")
    ap.add_argument("--seconds", type=float, default=12.0)
    ap.add_argument("--baud", type=int, default=115200)
    args = ap.parse_args()

    if args.sync:
        rc = run_sync(ext_uart=True)
        if rc != 0:
            sys.exit(rc)
        print("\nGowin → Reload All → Syn → PnR → Program")
        subprocess.call([sys.executable, str(ROOT / "tools" / "list_com_ports.py")])

    port = args.test or args.scan or "COM7"
    if args.scan:
        baud_scan(port)
    elif args.test or not args.sync:
        ok = uart_test(port, args.baud, args.seconds)
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
