# BL702 -> usb2uartjtag 플래시 안내 (Tang Nano 9K, 구조 B)
# Usage: powershell -File tools\flash_bl702.ps1 -Help

param(
    [string]$DfuCom = "",
    [string]$Firmware = "",
    [switch]$Help
)

if ($Help) {
    @"

=== Tang Nano 9K BL702 UART 브리지 복구 ===

문제: COM7에 'On Lichee Tang Nano-9K' 메뉴만 보이고 FPGA UART 없음
해결: BL702를 usb2uartjtag 펌웨어로 교체 (1회)

1) DFU 모드
   - USB 뽑기
   - 보드 USB-C 뒤 테스트포인트 2개 쇼트 (또는 BOOT 유지)
   - USB 연결 -> 새 COM (예: COM12)

2) 펌웨어 다운로드 (빌드 불필요)
   https://github.com/koshkin-sergey/Debugger_for_TANG_NANO-9K/releases/download/v1.0.0/usb2uartjtag_bl702.bin

3) 설치 & 플래시 (Python 3.13 은 telnetlib 패키지 필요)
   pip install bflb-mcu-tool telnetlib-313-and-up
   python -m bflb_mcu_tool --chipname=bl702 --port=COM12 --xtal=32M --firmware=usb2uartjtag_bl702.bin

   Python 3.13 에서 telnetlib 오류 나면 위 telnetlib-313-and-up 필수.
   또는 Bouffalo DevCube GUI 로 BL702 플래시.

4) USB 재연결 -> Gowin으로 FPGA Program -> uart_show.py

"@
    exit 0
}

if (-not $DfuCom -or -not $Firmware) {
    Write-Host "Usage: flash_bl702.ps1 -DfuCom COM12 -Firmware path\to\usb2uartjtag_bl702.bin"
    Write-Host "       flash_bl702.ps1 -Help"
    exit 1
}

python -m bflb_mcu_tool --chipname=bl702 --port=$DfuCom --xtal=32M --firmware=$Firmware
