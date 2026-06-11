# UART TX — PC 터미널에서 `HAEUN-16 Boot` 확인

**구조 B (온보드 BL702):** FPGA pin 17 → BL702 → USB COM. USB-TTL 동글 불필요.

| RTL | 역할 |
|-----|------|
| `uart_path_bl702.v` | pin 17 UART FIFO 경로 |
| `bl702_boot_delay.v` | S1 후 2s 대기 (BL702 USB 준비) |
| `fpga/BL702_ONBOARD.md` | **BL702 펌웨어 교체** (Lichee 메뉴 제거) |

Lichee 메뉴만 보이면 RTL 문제가 아니라 **BL702 펌웨어** → `tools\flash_bl702.ps1 -Help`

---

## 1. 비트스트림 준비 (최초 1회 / RTL 수정 후)

```powershell
cd path\to\CPUmaking\HAEUN16
powershell -File tools\sync_gowin.ps1
```

Gowin IDE:

1. Design에 **`uart_path_bl702.v`**, **`bl702_boot_delay.v`** 포함 (`sync_gowin.ps1`)
2. **Synthesize** → **Place & Route**
3. `impl\pnr\HAEUN16_9K.fs` 생성 확인

> `uart_fifo_tx.v` — CPU가 UART보다 빠를 때 바이트가 유실되지 않도록 FIFO 추가 (boot 문자열 전체 전송).

---

## 2. 보드 연결

1. Tang Nano 9K **USB-C** → PC
2. 장치 관리자에서 **COM 포트 2개** 확인
   - 하나: JTAG (Programmer)
   - 하나: **USB-UART** (보통 **번호가 큰 COM**)

---

## 3. 비트스트림 다운로드

1. Gowin **Program Device**
2. Open → `HAEUN16_9K.fs`
3. **Program** → Success

---

## 4. 시리얼 터미널

| 설정 | 값 |
|------|-----|
| 포트 | USB-UART COM (JTAG 아님) |
| Baud | **115200** |
| Data | 8 |
| Parity | None |
| Stop | 1 |
| Flow | None |

**PuTTY / Tera Term / Arduino Serial Monitor**

PowerShell (예: COM5):

```powershell
python -m serial.tools.miniterm COM5 115200
```

(`pip install pyserial` 필요)

---

## 5. 확인

1. 터미널 **먼저** 연결
2. 보드 **S1** 리셋 (눌렀다 떼기)
3. 기대 출력:

```text
HAEUN-16 Boot
> 
```

4. **LED 6개 ON** (R1=1, boot 완료)

`>` 는 무한 반복 (정상).

---

## 핀 (Tang Nano 9K)

| FPGA 핀 | 신호 |
|---------|------|
| **17** | `uart_tx` (FPGA → PC, 회로도 FPGA_TX) |
| 18 | `uart_rx` (FPGA ← PC, 향후) |

BL702 온보드 USB-UART에 **내부 연결** — 외부 동글 불필요.

### BL702 배너만 보임 (`uart_show`에 HAEUN 없음)

`____ On Lichee...` 만 나오면 **COM은 맞지만 FPGA TX가 PC까지 안 옴**.

```text
1. Gowin → Syn + PnR + Program (top_tangnano9k, pin 17)
2. Gowin 완전 종료 → USB 뽑았다 꽂기
3. python tools\uart_show.py COM7   (After S1 구간에 HAEUN?)
4. 안 되면: python tools\uart_show.py COM6
5. 그래도 안 되면 스모크:
   Hierarchy → top_uart_smoke → Set as Top → Syn+Pnr+Program
   python tools\uart_show.py COM7   (UART_OK 기대)
```

스모크 후 **top_tangnano9k** 로 되돌려 다시 Program.

### 스모크해도 COM7에 BL702 메뉴만 (지금 상태)

Gowin 로그에 `Current top module is "top_uart_smoke"` 인데도 `UART_OK`가 없고
`On Lichee...` 만 보이면 **FPGA RTL은 맞고, 온보드 BL702 UART 브리지가 FPGA TX를
PC로 안 넘기는 보드 이슈**입니다 ([동일 증상 보고](https://github.com/lushaylabs/tangnano9k-series-examples/issues/15)).

**해결: 외부 USB-TTL (3.3V)**

| 연결 | |
|------|--|
| FPGA **pin 37** | USB-TTL **RX** |
| **GND** | GND |

1. Gowin에서 `tangnano9k.cst` **disable** → `tangnano9k_ext_uart.cst` **enable**
2. Syn + PnR + Program (`top_tangnano9k` 또는 smoke)
3. PC는 **USB-TTL의 새 COM** (보드 COM7 아님), 115200
4. `python tools\uart_show.py COMx` (x = 동글 COM)

### 터미널 확인

```powershell
python -m serial.tools.miniterm COM7 115200
```

S1 누른 뒤 `HAEUN-16 Boot` (한 줄, 115200 고정).

### BL702 메뉴가 보일 때 (정상)

COM7에 아래처럼 나오면 **포트는 맞습니다**. BL702 디버거 펌웨어 메뉴입니다.

```text
On Lichee Tang Nano-9K
Select an action: [1] Toggle led 1 ...
```

FPGA UART는 이와 **같은 COM**으로 올라옵니다. 메뉴 아래에 `HAEUN-16 Boot` / `UART_OK`가 이어져야 합니다.

---

## 안 나올 때

### LED 6개 ON인데 FPGA 문자열만 없음

| 원인 | 해결 |
|------|------|
| **TX가 pin 18** (RX 핀에 연결됨) | `tangnano9k.cst` → **pin 17** → Syn + PnR + Program |
| 구버전 `.fs` | `uart_fifo_tx.v` 포함 재빌드 |
| JTAG COM | **번호가 큰 COM**(UART) 사용 |
| Program 직후 | Gowin 종료 → USB 재연결 |

CPU 부트는 끝났지만 PC로 FPGA UART가 안 올라온 경우, **pin 17 (FPGA_TX)** 배선을 먼저 확인합니다.

1. **Gowin Programmer 완전 종료** (JTAG가 UART를 막을 수 있음)
2. **USB Type-C 뽑았다 다시 꽂기** ([Sipeed Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-Doc/questions.html))
3. **번호가 큰 COM** (예: COM7)에 115200 연결 — COM6은 JTAG일 수 있음
4. 아래 **하드웨어 스모크**로 CPU를 제외하고 TX만 검증

### 하드웨어 스모크 (`top_uart_smoke`)

```text
1. powershell -File tools\sync_gowin.ps1
2. Gowin: src에 uart_msg_tx.v, top_uart_smoke.v 추가 (sync가 복사함)
3. Hierarchy → top_uart_smoke 우클릭 → Set as Top
4. Syn + PnR + Program
5. Gowin 종료 → USB 재연결
6. python -m serial.tools.miniterm COM7 115200
```

기대 출력: `UART_OK` 가 반복. LED0만 깜빡임.

| 스모크 결과 | 의미 |
|------------|------|
| `UART_OK` 보임 | pin 17/BL702 정상 → `top_tangnano9k`로 되돌려 CPU/FIFO 쪽 재확인 |
| 여전히 0바이트 | 드라이버·케이블·USB 포트·BL702; 다른 PC/케이블 시도 |

스모크 후 **Hierarchy → top_tangnano9k** 로 되돌린 뒤 다시 Program.

### 기타

| 증상 | 확인 |
|------|------|
| 아무것도 없음 | 위 스모크 + USB 재연결 + UART COM(번호 큰 쪽) |
| 일부 글자만 | `uart_fifo_tx.v` 없는 구버전 bitstream |

```powershell
python tools\uart_try_baud.py COM5
```

---

## 시뮬 검증

```powershell
iverilog -o tb_uart_boot_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v uart_fifo_tx.v tb_uart_boot.v
vvp tb_uart_boot_sim
```

→ `*** BOOT UART TEST PASS ***`
