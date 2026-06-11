# Tang Nano 9K — 온보드 BL702 UART (구조 B)

USB-TTL 동글 없이 **보드 USB → BL702 → FPGA pin 17** 경로를 씁니다.

## 신호 경로

```text
HAEUN-16 OUT → uart_path_bl702 → pin 17 (FPGA_TX)
    → BL702 UART1_RX → USB FTDI → PC COM (UART, 보통 번호 큰 COM)
```

RTL: `bl702_boot_delay` (2s) → CPU 부트 → `uart_path_bl702`

## 1. BL702 펌웨어 (필수, 1회)

`On Lichee Tang Nano-9K` 메뉴만 보이고 FPGA 문자열이 안 오면,
BL702가 **대화형 펌웨어**라 FPGA UART 패스스루가 안 되는 경우입니다.

**표준 usb2uartjtag** 로 교체:

1. 보드 **DFU**: USB-C 뒤 **테스트 포인트 2개 쇼트** (또는 BOOT) 후 USB 연결
2. 장치 관리자에 **새 COM (CDC)** 나타남
3. 펌웨어 빌드/다운로드:
   - [Debugger_for_TANG_NANO-9K](https://github.com/koshkin-sergey/Debugger_for_TANG_NANO-9K)
   - 또는 [RV-Debugger-BL702](https://github.com/sipeed/RV-Debugger-BL702) `usb2uartjtag_bl702.bin`
4. 플래시:

```powershell
pip install bflb-mcu-tool
python -m bflb_mcu_tool --chipname=bl702 --port=COM12 --xtal=32M --firmware="usb2uartjtag_bl702.bin"
```

(COM12 = DFU 모드 COM)

5. USB 뽑았다 꽂기 → **Lichee 메뉴 없음**, 조용한 UART 브리지 기대

자세한 절차: `tools/flash_bl702.ps1 -Help`

## 2. FPGA 비트스트림

```powershell
powershell -File tools\sync_gowin.ps1
```

Gowin: **top_tangnano9k**, `tangnano9k.cst` (pin 17), Syn + PnR + Program

## 3. PC에서 확인

1. Gowin **완전 종료**
2. USB 재연결
3. COM **번호 큰 쪽**, **115200**

```powershell
python tools\uart_show.py COM7
```

S1 누르면 2초 후 `HAEUN-16 Boot` (부트 딜레이)

## 4. 스모크

Hierarchy → `top_uart_smoke` → Program → `UART_OK` on COM7

## 외부 USB-TTL (선택)

온보드가 계속 안 되면 `tangnano9k_ext_uart.cst` (pin 37) — `UART_TX.md` 참고
