# Tang Nano 9K — 온보드 BL702 UART (구조 B)

> **BL702 플래시/DFU가 안 되면** → [EXT_UART_KEYBOARD.md](EXT_UART_KEYBOARD.md) (외부 USB-TTL, pin 37/38)

USB-TTL 동글 없이 **보드 USB → BL702 → FPGA pin 17** 경로를 씁니다.

## 신호 경로

```text
HAEUN-16 OUT → uart_path_bl702 → pin 17 (FPGA_TX)
    → BL702 UART1_RX → USB FTDI → PC COM (UART, 보통 번호 큰 COM)
```

RTL: `bl702_boot_delay` (2s) → CPU 부트 → `uart_path_bl702`

## COM6 vs BL702 DFU (헷갈리기 쉬운 부분)

Tang Nano 9K USB **하나**에서 PC로 **여러 장치**가 잡힙니다. **COM 번호만** 보고 고르면 안 됩니다.

| 용도 | 맞는 COM | 장치 관리자에서 보이는 것 |
|------|----------|---------------------------|
| **Gowin FPGA Program** | **COM6** (지금 환경) | `USB Serial Port`, VID `0403:6010`, `FACTORYAIOT_PROG` |
| **BL702 펌웨어 플래시 (DFU)** | **COM6 아님** | DFU 진입 시 **새로 추가**되는 `CDC` / `USB Serial Device` (Bouffalo) |
| **키보드 UART 터미널** | **COM6 아님** | 플래시 후 `USB Converter A/B` 또는 **번호 큰 UART COM** |

**COM6이 맞는 경우:** Gowin으로 `HAEUN16_SOC.fs` 넣을 때만.

**COM6이 틀린 경우:** `bflb_mcu_tool` BL702 플래시, miniterm 키board 입력.

플래시 로그 `handshake failed` + `0xf8f8...` = COM6(FTDI JTAG)이 BL702 부트로더 handshake에 **응답하지 않음** → 포트는 열렸지만 **칩이 BL702 DFU가 아님**.

```powershell
python tools\list_com_ports.py
# COM6 hwid: FACTORYAIOT_PROG  → JTAG (플래시/키보드 X)

python tools\dfu_find_com.py watch
# DFU 진입 시 FACTORYAIOT_PROG 말고 새 COM이 떠야 함
```

Sipeed 위키: BL702 DFU 성공 후 Windows에 **USB Converter A / B** 두 개가 보여야 정상.

## 1. BL702 펌웨어 (필수, 1회)

`On Lichee Tang Nano-9K` 메뉴만 보이고 FPGA 문자열이 안 오면,
BL702가 **대화형 펌웨어**라 FPGA UART 패스스루가 안 되는 경우입니다.

**표준 usb2uartjtag** 로 교체:

1. 보드 **DFU** (아래 순서 중 하나)
   - **702-BOOT** 흰색 버튼 **누른 채** USB-C 연결
   - 또는 USB 뽑기 → USB-C **뒤쪽** 테스트포인트 **2개 쇼트** 유지 → USB 연결
2. 장치 관리자에 **새 COM (CDC Virtual ComPort)** 나타남
   - **COM6(JTAG), COM11~18(Bluetooth) 아님**
   - DFU COM 찾기:

```powershell
python tools\dfu_find_com.py snapshot before
# DFU 진입 + USB 연결
python tools\dfu_find_com.py snapshot after
python tools\dfu_find_com.py diff
```

3. 펌웨어: repo 루트 `usb2uartjtag_bl702.bin` (또는 [릴리스](https://github.com/koshkin-sergey/Debugger_for_TANG_NANO-9K/releases/download/v1.0.0/usb2uartjtag_bl702.bin))
4. 플래시 (**diff가 알려준 COM만** 사용):

```powershell
pip install bflb-mcu-tool telnetlib-313-and-up
python -m bflb_mcu_tool --chipname=bl702 --port=COM?? --xtal=32M --firmware=usb2uartjtag_bl702.bin
```

### 플래시 실패 시 (BFLB LOAD HELP BIN FAIL)

| 사용한 COM | 원인 |
|------------|------|
| **COM6** | Gowin **JTAG(FTDI)** — BL702 아님 → handshake failed |
| **COM11~18** | **Bluetooth** — BL702 아님 → Write timeout |
| **CDC COM**인데 실패 | DFU 타이밍: Gowin/miniterm **종료**, USB **재연결** 후 **즉시** 플래시 |

COM6/COM12로 플래시하면 **항상 실패**합니다. `python tools\list_com_ports.py`로 확인하세요.

**DFU COM이 전혀 안 뜨면** (watch에 COM6만): BL702 부트로더 USB가 열리지 않은 것 → **외부 USB-TTL** 로 진행 ([EXT_UART_KEYBOARD.md](EXT_UART_KEYBOARD.md)). Bouffalo [BLDevCube](https://wiki.sipeed.com/hardware/en/tang/common-doc/update_debugger.html) GUI도 동일하게 **CDC COM** 필요.

5. USB 뽑았다 꽂기 → **Lichee 메뉴 없음**, 조용한 UART 브리지 기대

자세한 절차: `tools/flash_bl702.ps1 -Help`

## 2. FPGA 비트스트림

```powershell
powershell -File tools\sync_gowin.ps1
```

Gowin: **top_tangnano9k**, `tangnano9k.cst` (pin 17), Syn + PnR + Program

## 3. PC에서 확인

먼저 COM 상태 확인:

```powershell
python tools\list_com_ports.py
```

| 진단 결과 | 의미 |
|-----------|------|
| **COM6만 + JTAG** | miniterm COM6은 **키보드 불가** (깨진 바이너리 정상) |
| **UART COM 1개+** | Gowin 종료 후 그 COM으로 터미널 |

1. Gowin **완전 종료**
2. USB 재연결
3. COM **번호 큰 쪽**(UART), **115200** — JTAG(COM6) 아님

```powershell
python tools\uart_show.py COM7
```

S1 누르면 2초 후 `HAEUN-16 Boot` (부트 딜레이)

**지금 PC에 JTAG COM만 보이면** → BL702 플래시(§1) 또는 §외부 USB-TTL 필수.

## 4. 스모크

Hierarchy → `top_uart_smoke` → Program → `UART_OK` on COM7

## 외부 USB-TTL (온보드 UART COM 없을 때)

| 연결 | |
|------|--|
| FPGA **pin 37** | USB-TTL **RX** |
| FPGA **pin 38** | USB-TTL **TX** (키보드 입력) |
| **GND** | GND |

- CPU만: `tangnano9k_ext_uart.cst` (pin 37/38)
- SOC+HDMI: `soc/tangnano9k_soc_ext_uart.cst` — Gowin에서 `tangnano9k_soc.cst` 대신 사용

PC는 **동글 COM**, 115200. 보드 COM6(JTAG) 사용 금지.

자세히: `UART_TX.md`
