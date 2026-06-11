# 키보드 입력 — BL702 플래시 없이 (외부 USB-TTL)

BL702 DFU가 안 되거나 온보드 UART COM이 없을 때 **이 경로로 키보드 에코**를 씁니다.
(BL702/보드 USB는 Gowin JTAG COM6만 — 터미널 불가)

## 필요한 것

- **USB-TTL 3.3V** (CH340 / CP2102 / FT232 등, **5V 전용 동글 X**)
- **점퍼선** 3~4개 (또는 브레드보드)

## 배선 (Tang Nano 9K 헤더)

보드 **전원은 USB-C 디버그 포트**로 켠 상태. 동글은 **FPGA 핀만** 연결.

| Tang Nano 핀 | USB-TTL | 방향 |
|--------------|---------|------|
| **37** | **RX** | FPGA TX → PC 수신 |
| **38** | **TX** | PC 송신 → FPGA RX |
| **GND** | **GND** | 공통 |

핀 37/38 위치: 보드 **TF 카드 슬롯 옆** 2×24 헤더 (Sipeed 핀아웃 참고).

## Gowin (HAEUN16_SOC)

```powershell
cd HAEUN16
powershell -File tools\sync_soc_gowin.ps1 -ExtUart
```

Gowin IDE:

1. `HAEUN16_SOC.gprj` 열기 → **Project → Reload All**
2. **Design** 창에서 `tangnano9k_soc.cst` 가 **ext_uart(pin 37/38)** 인지 확인
3. **Synthesize → Place & Route → Program** (top: `top_haeun16_soc`)

## PC 터미널

1. Gowin **종료**
2. USB-TTL을 PC에 연결 → **새 COM** 확인:

```powershell
python tools\list_com_ports.py
# CH340 / CP2102 등 "외부 USB-TTL" 로 표시된 COM
```

3. 터미널 (115200, 8N1):

```powershell
python -m serial.tools.miniterm COM?? 115200
```

4. 보드 **S1** 리셋 → HDMI에 `HAEUN-OS v0.1` / `>` 확인
5. 키 입력 → **UART + HDMI** 에코 (`help` 등)

## 확인

| 증상 | 조치 |
|------|------|
| HDMI만 되고 UART 무반응 | cst가 ext_uart인지, pin 37↔RX / 38↔TX 교차 확인 |
| 동글 COM 없음 | CH340 드라이버 설치 |
| 글자 깨짐 | 115200 고정, 3.3V 동글인지 확인 |

온보드 BL702 복구는 나중에 [BL702_ONBOARD.md](BL702_ONBOARD.md) + Bouffalo **BLDevCube** GUI 로 시도 가능 (DFU CDC COM 필요).
