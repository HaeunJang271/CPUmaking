# HAEUN-16

Verilog-2001 기반 **16비트 CPU** 프로젝트.  
RTL · ISA v1/v2 · 시뮬 · UART 부트 펌웨어 · Tang Nano 9K **FPGA 실기 동작(LED)** 까지 완료.  
**다음 단계:** UART TX 터미널 확인 → UART RX → 모니터 프로그램.

---

## 현재 상태

| 구분 | 상태 |
|------|------|
| CPU 코어 (1~8단계) | 완료 |
| ISA v2 (JZ / CALL / RET / OUT / IN) | 완료 |
| 시뮬 (`tb_cpu`, `tb_cpu_all`, `tb_cpu_v2`) | **PASS** |
| UART + `boot.asm` | RTL + 시뮬 완료 |
| FPGA RTL (`top`, `uart_tx`, `cst`, `sdc`) | 완료 |
| Gowin Syn + PnR → `HAEUN16_9K.fs` | 완료 |
| **보드 Program + LED 실기** | **완료** ✓ |
| UART TX (`uart_fifo_tx`) | RTL + 시뮬 PASS |
| 보드 UART 터미널 확인 | **다음** → [UART_TX.md](UART_TX.md) |

```text
RTL + 시뮬 + 펌웨어     ████████████████████  100%
Gowin 빌드              ████████████████████  100%
보드 Program + LED      ████████████████████  100%  ← 실기 검증 완료
UART TX (보드)          ██░░░░░░░░░░░░░░░░░░   ~10%
UART RX / 모니터        ░░░░░░░░░░░░░░░░░░░░    ~0%
```

### 한 줄 답

| 질문 | 답 |
|------|-----|
| CPU 만들었나? | **예** — RTL + 시뮬 PASS |
| FPGA에서 돌아가나? | **예** — Tang Nano 9K LED 실기 확인 완료 |
| OS 올릴 기반? | **예** — 분기·호출·UART TX까지 있음 |
| 다음은? | UART 출력 확인 → **UART RX** → 모니터 |

---

## 보드 실기 (완료)

Tang Nano 9K에서 확인된 동작:

1. `HAEUN16_9K.fs` **Program Device** 성공
2. **S1** 리셋 후 CPU 부팅
3. 부팅 중 **LED 패턴 변화(깜빡임)** — `r0` 하위 6비트 표시 (`~r0[5:0]`)
4. boot 완료 후 **LED 6개 ON** — `R1=1` (`done` 신호)

```verilog
// 부팅 중: led = ~r0[5:0]  → 실행에 따라 패턴 변화
// 완료 후: led = 6'b000000 → 6개 전부 ON (active-low)
wire done = (r1 == 16'd1);
assign led = done ? 6'b000000 : ~r0[5:0];
```

재현 절차: **[BOARD_QUICKSTART.md](BOARD_QUICKSTART.md)**

### UART TX (다음 할 일)

→ **[UART_TX.md](UART_TX.md)** — 온보드 USB-UART, 별도 배선 없음

1. `sync_gowin.ps1` → **Syn + PnR** (`uart_fifo_tx.v` 포함)
2. Program → COM **UART 포트** → **115200 8N1**
3. 리셋 → `HAEUN-16 Boot` / `> `

---

## 아키텍처

```
                    ┌─────────────┐
  27MHz ───────────▶│ top         │──▶ LED[5:0]
                    │             │──▶ uart_tx (pin 17)
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │ cpu (HAEUN-16)        │
              │  R0~R3, ALU, PC, FSM  │
              └────────────┬──────────┘
                           │
              ┌────────────┴──────────┐
              │ ram_fpga 256×16       │
              │ boot.asm @ 0..36      │
              └───────────────────────┘
```

| 항목 | 내용 |
|------|------|
| 명령어 | NOP, LOAD, STORE, ADD, SUB, AND, OR, XOR, JMP, **JZ, CALL, RET, OUT, IN** |
| 사이클 | Fetch1 → Fetch2 → Execute (STORE / CALL / RET 추가 사이클) |
| 스택 | `sp` 255↓, CALL/RET용 |
| I/O | `OUT Rs, 0` → UART TX |

상세: [ISA.md](ISA.md)

---

## 폴더 구조

```
HAEUN16/
├── cpu.v, alu.v, pc.v, register16.v
├── ram.v                  # 65536 word (시뮬 전용)
├── ram_fpga.v             # 256 word + boot initial
├── uart_tx.v, uart_fifo_tx.v  # 115200 8N1 + FIFO
├── top_tangnano9k.v
├── tangnano9k.cst         # 핀 (LED, clk, rst, uart_tx)
├── tangnano9k.sdc         # 27 MHz create_clock
├── program.mi             # boot BRAM init (= programs/boot.mi)
├── tb_*.v, tb_cpu_all.v, tb_cpu_v2.v
├── ISA.md, BOARD_QUICKSTART.md, COMPLETION.md
├── fpga/GOWIN_PROJECT.md
├── tools/
│   ├── asm.py             # 라벨 2-pass 어셈블러
│   └── sync_gowin.ps1     # repo → Gowin src 동기화
└── programs/
    ├── demo.asm, test_all.asm, test_v2.asm
    ├── boot.asm, BOOT.md
    └── TEST_ALL.md
```

**Gowin 프로젝트 (IDE 별도 폴더):**  
`C:\Gowin\...\Documents\HAEUN16_9K\` — `src\`, `HAEUN16_9K.gprj`, `impl/pnr/*.fs`

> repo `HAEUN16/` 와 Gowin `src\` 는 **별도 복사본**. RTL 수정 후 `sync_gowin.ps1` 필수.

---

## 시뮬레이션 (Icarus Verilog)

```powershell
cd path\to\CPUmaking\HAEUN16
```

### demo (R0=8) — `tb_cpu.v`가 RAM을 demo로 덮어씀

```powershell
iverilog -o tb_cpu_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu.v
vvp tb_cpu_sim
```

### 전 opcode v1

```powershell
python tools\asm.py programs\test_all.asm
iverilog -o tb_cpu_all_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu_all.v
vvp tb_cpu_all_sim
```

### ISA v2 + UART

```powershell
python tools\asm.py programs\test_v2.asm
iverilog -o tb_cpu_v2_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v tb_cpu_v2.v
vvp tb_cpu_v2_sim
```

### boot UART (FIFO)

```powershell
iverilog -o tb_uart_boot_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v uart_fifo_tx.v tb_uart_boot.v
vvp tb_uart_boot_sim
```

### 부트 펌웨어

```powershell
python tools\asm.py programs\boot.asm
python tools\asm.py programs\boot.asm --verilog   # ram_fpga initial 스니펫
```

---

## 어셈블러 (`tools/asm.py`)

- **라벨:** `LOOP:`, `JMP LOOP`, `CALL SEND`
- **출력:** 콘솔 hex + `programs/*.mi`
- **옵션:** `--verilog` → `ram_fpga` initial용 `$display` 스니펫

```asm
SEND:
    OUT R0, 0
    RET
BOOT:
    LOAD R0, 72      ; 'H'
    CALL SEND
```

---

## FPGA — Tang Nano 9K

### 툴·디바이스

| 항목 | 값 |
|------|-----|
| 툴 | GOWIN EDA (Education) |
| 보드 | Sipeed Tang Nano 9K |
| FPGA | **GW1NR-LV9QN88PC6/I5** (QN88) |
| 클럭 | 27 MHz |

**주의:** `GW1N-9` + LQ144 ≠ 9K. **GW1NR-9 + QN88**.

### Gowin Design 파일

```
top_tangnano9k.v
cpu.v, alu.v, pc.v, register16.v, ram_fpga.v, uart_tx.v, uart_fifo_tx.v
tangnano9k.cst
tangnano9k.sdc      ← FileList에 반드시 등록 (TA1132)
```

**제외:** `tb_*.v`, `ram.v`

### 소스 동기화 (권장)

```powershell
cd path\to\CPUmaking\HAEUN16
powershell -File tools\sync_gowin.ps1
```

- repo RTL → Gowin `src\` 복사
- `HAEUN16_9K.gprj`에 `tangnano9k.sdc` 없으면 자동 추가

Gowin IDE: **Process → Reload All** → **Synthesize** → **Place & Route**

### 빌드 체크리스트

1. Top: `top_tangnano9k`
2. `uart_tx.v` 포함
3. `cpu.v`와 `top` **같은 버전** (IO 포트 일치)
4. `tangnano9k.sdc`가 Design 트리에 보임
5. **Use DONE as regular IO** 체크
6. 산출: `impl/pnr/HAEUN16_9K.fs`

상세: [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md)

### 자주 나는 Gowin 메시지

| 메시지 | 원인 | 해결 |
|--------|------|------|
| `EX3990` `io_out_strobe` 없음 | Gowin `cpu.v` 구버전 | `sync_gowin.ps1` 후 Reload |
| `TA1132` sys_clk not created | `.sdc`가 `.gprj`에 없음 | Add File 또는 `sync_gowin.ps1` |

### 보드 LED (top) — 실기 확인됨

| 단계 | LED | 의미 |
|------|-----|------|
| 부팅 중 | 패턴 변화 / 깜빡임 | CPU 실행 중 (`~r0[5:0]`) |
| boot 완료 | **6개 전부 ON** | `R1=1`, 펌웨어 정상 종료 |

### 프로그램 / RAM

| 용도 | 방법 |
|------|------|
| FPGA boot | `ram_fpga.v` initial (boot 37 word) |
| BRAM init | `program.mi` / `programs/boot.mi` |
| demo로 되돌리기 | `python tools\asm.py programs\demo.asm` → initial 갱신 |

---

## RAM

| 모듈 | 크기 | 용도 |
|------|------|------|
| `ram.v` | 65536×16 | 시뮬 only |
| `ram_fpga.v` | 256×16 | CPU + FPGA (9K BSRAM) |

---

## 타임라인

| 단계 | 산출물 |
|------|--------|
| 1~5 | `adder16`, `register16`, `alu`, `pc`, `ram` + tb |
| 6~8 | `ISA.md`, `cpu.v`, `tb_cpu.v` |
| 검증 | `test_all.asm`, `tb_cpu_all.v` |
| v2 | JZ/CALL/RET/OUT/IN, `test_v2.asm`, `tb_cpu_v2.v` |
| 펌웨어 | `boot.asm`, `asm.py` 라벨, `uart_tx.v` |
| FPGA | `top_tangnano9k`, `cst`, `sdc`, Gowin `HAEUN16_9K` |
| **보드** | Program + LED 깜빡임 → 6개 ON **실기 PASS** |

---

## 문서

| 문서 | 설명 |
|------|------|
| [ISA.md](ISA.md) | 명령어 집 v1+v2 |
| [UART_TX.md](UART_TX.md) | PC 터미널 UART TX 확인 |
| [programs/BOOT.md](programs/BOOT.md) | UART 부트 |
| [programs/TEST_ALL.md](programs/TEST_ALL.md) | v1 opcode 테스트 |
| [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md) | 보드 10분 |
| [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md) | Gowin IDE |
| [COMPLETION.md](COMPLETION.md) | 빠른 완성 |
| [FPGA_RTL_REVIEW.md](FPGA_RTL_REVIEW.md) | RTL 검토 |

---

## 다음 작업 (우선순위)

1. **UART TX** — 터미널에서 `HAEUN-16 Boot` 확인 (USB-UART)
2. **UART RX** (pin 18) + `IN` — 양방향 콘솔
3. **모니터** — `help` / `echo` / `reboot` (asm)
4. RAM 확장 / 메모리 LOAD / OS — 이후

## 향후 (선택)

- PSRAM / SD / VGA
- 인터럽트, 타이머, 멀티태스킹

---

## 참고

- [Icarus Verilog](https://bleyer.org/icarus/)
- [Tang Nano 9K Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)

교육/개인 프로젝트.
