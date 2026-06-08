# HAEUN-16

Verilog-2001로 설계한 **16비트 CPU** 프로젝트입니다.  
모듈별 테스트벤치·ISA v1/v2·통합 시뮬·**UART 부트 펌웨어**·**Tang Nano 9K** FPGA RTL까지 완료했습니다.  
**남은 단계:** 보드 Program → LED / UART 확인.

---

## 현재 상태 (요약)

| 구분 | 상태 |
|------|------|
| CPU RTL (1~8단계) | 완료 |
| 시뮬 (`tb_cpu`, `tb_cpu_all`, `tb_cpu_v2`) | PASS |
| ISA v2 (JZ/CALL/RET/OUT/IN) | 완료 |
| UART + `boot.asm` | RTL + 시뮬 완료 |
| FPGA RTL (`ram_fpga`, `top`, `uart_tx`, `cst`, `sdc`) | 완료 |
| Gowin Synthesize + Place & Route | 이전 빌드 완료 (UART 추가 후 **재PnR 필요**) |
| **보드 실기 확인** | **대기** — LED / UART |

```text
CPU + 시뮬 + Gowin PnR    ████████████████████  100% (소프트웨어)
보드 Program + LED        ░░░░░░░░░░░░░░░░░░░░    ~5% (하드웨어 확인)
```

---

## 프로젝트 목표

| 목표 | 상태 |
|------|------|
| 16비트 CPU 설계 | 완료 |
| Verilog RTL 작성 | 완료 |
| 시뮬레이션 검증 | 완료 (Icarus Verilog) |
| 전 opcode 테스트 | 완료 (`tb_cpu_all` PASS) |
| ISA 문서 | 완료 (`ISA.md` v1+v2) |
| 어셈블러 (라벨) | 완료 (`tools/asm.py`) |
| UART 부트 펌웨어 | 완료 (`programs/boot.asm`) |
| FPGA 이식 RTL | 완료 |
| Gowin 합성·Place & Route | 완료 (`GW1NR-LV9QN88PC6/I5`) |
| 타이밍 제약 (TA1132) | 완료 (`tangnano9k.sdc`) |
| FPGA 보드 실기 동작 | **대기** |
| VGA / 파일시스템 / OS | 향후 과제 |

### CPU를 만들었나? / FPGA에서 돌아가나?

| 질문 | 답 |
|------|-----|
| CPU를 만들었나? | **예.** RTL + 시뮬 PASS |
| FPGA 비트스트림? | **예.** `.fs` 생성 완료 |
| 보드에서 확인? | **Program Device** 후 **LED 6개 ON** = 최종 완성 |

---

## 다음에 할 일 (보드 있을 때)

→ **[BOARD_QUICKSTART.md](BOARD_QUICKSTART.md)** (약 10분)

1. USB 연결 → Gowin **Program Device**
2. `top_tangnano9k.fs` 다운로드
3. **S1** 버튼 눌렀다 떼기
4. **LED 6개 ON** + 시리얼 **115200** → `HAEUN-16 Boot` / `> ` (boot 펌웨어, R1=1)

보드 없으면: `.fs`만 보관해 두면 됩니다. 추가 Gowin 작업 불필요.

---

## 지금까지 한 일 (타임라인)

### CPU 코어 (1~8단계)

| 단계 | 산출물 | 검증 |
|------|--------|------|
| 1 | `adder16.v`, `tb_adder16.v` | 5+3=8, 65535+1 오버플로 |
| 2 | `register16.v`, `tb_register16.v` | load/hold/reset |
| 3 | `alu.v`, `tb_alu.v` | ADD/SUB/AND/OR/XOR, ZERO |
| 4 | `pc.v`, `tb_pc.v` | +1, jump, reset |
| 5 | `ram.v`, `tb_ram.v` | 64KW RAM (시뮬용) |
| 6 | `ISA.md` | 16bit 명령어·R0~R3 |
| 7 | `cpu.v` | Fetch1→Fetch2→Exec, 9 opcode |
| 8 | `tb_cpu.v` | demo → R0=8 PASS |

### 검증·도구

| 항목 | 파일 | 내용 |
|------|------|------|
| 전 opcode v1 | `programs/test_all.asm`, `tb_cpu_all.v` | NOP~JMP PASS |
| ISA v2 | `programs/test_v2.asm`, `tb_cpu_v2.v` | JZ/CALL/RET/OUT PASS |
| 어셈블러 | `tools/asm.py` | 라벨 2-pass, `.mi`, `--verilog` |
| 부트 | `programs/boot.asm`, `programs/BOOT.md` | UART 문자열 출력 |

### FPGA (Tang Nano 9K)

| 단계 | 산출물 | 내용 |
|------|--------|------|
| 준비 | Gowin EDA (Education) | 라이선스 불필요 |
| 검토 | [FPGA_RTL_REVIEW.md](FPGA_RTL_REVIEW.md) | RTL FPGA 관점 검토 |
| RAM | `ram_fpga.v`, `cpu.v` | 256×16 word (9K BSRAM) |
| Top | `top_tangnano9k.v` | UART TX + LED, 27MHz |
| UART | `uart_tx.v` | 115200 8N1, pin 17 |
| 제약 | `tangnano9k.cst`, `tangnano9k.sdc` | 핀 + 27MHz 클럭 |
| 빌드 | `HAEUN16_9K` Gowin 프로젝트 | Syn + PnR 완료 |
| 문서 | [GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md), [COMPLETION.md](COMPLETION.md) | IDE·완성 가이드 |

### 보드 LED (top)

```verilog
wire done = (r1 == 16'd1);   // boot.asm 완료 마커
assign led = done ? 6'b000000 : ~r0[5:0];
```

---

## 폴더 구조

```
HAEUN16/
├── adder16.v, register16.v, alu.v, pc.v
├── ram.v                  # 65536 word (시뮬 전용)
├── ram_fpga.v             # 256 word (CPU/FPGA)
├── cpu.v
├── top_tangnano9k.v       # Tang Nano 9K top (UART + LED)
├── uart_tx.v              # UART 송신 115200
├── tangnano9k.cst         # 핀 제약
├── tangnano9k.sdc         # 27MHz create_clock (TA1132)
├── program.mi             # demo BRAM init
├── tb_*.v, tb_cpu_all.v, tb_cpu_v2.v
├── ISA.md
├── FPGA_RTL_REVIEW.md
├── COMPLETION.md
├── BOARD_QUICKSTART.md
├── fpga/GOWIN_PROJECT.md
├── tools/asm.py
├── programs/
│   ├── demo.asm
│   ├── test_all.asm, test_v2.asm
│   ├── boot.asm, BOOT.md
│   └── TEST_ALL.md
└── README.md
```

**Gowin 프로젝트 (별도 폴더):** `HAEUN16_9K/` — `.gprj`, `impl/pnr/top_tangnano9k.fs`  
**git 제외 권장:** `*_sim`, `impl/`

---

## 개발 규칙

1. 모듈별 개별 `.v`  
2. 모듈마다 `tb_*.v`  
3. Verilog-2001, 합성 가능 RTL  
4. 콘솔 메시지 영문 (터미널 인코딩)  
5. 단계별 검증 후 통합  

---

## 아키텍처

```
┌─────────┐     ┌──────────────┐     ┌─────────────┐
│ PC      │────▶│ ram_fpga     │◀───▶│ cpu         │
└─────────┘     │ 256×16bit    │     │ R0~R3, ALU  │
                └──────────────┘     └─────────────┘
```

- **명령:** NOP, LOAD, STORE, ADD, SUB, AND, OR, XOR, JMP, **JZ, CALL, RET, OUT, IN**  
- **사이클:** Fetch1 → Fetch2 → Execute (STORE +1)  
- 상세: [ISA.md](ISA.md)

---

## 시뮬레이션 (Icarus Verilog)

```powershell
cd path\to\CPUmaking\HAEUN16
```

### demo (R0=8)

```powershell
iverilog -o tb_cpu_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu.v
vvp tb_cpu_sim
```

| 주소 | 명령 | Hex |
|------|------|-----|
| 0 | LOAD R0, 5 | `1005` |
| 1 | LOAD R1, 3 | `1403` |
| 2 | ADD R0, R1 | `3100` |

### 전 opcode

```powershell
python tools\asm.py programs\test_all.asm
iverilog -o tb_cpu_all_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu_all.v
vvp tb_cpu_all_sim
```

→ `*** ALL OPCODE TESTS PASS ***` — [programs/TEST_ALL.md](programs/TEST_ALL.md)

### ISA v2 + UART

```powershell
python tools\asm.py programs\test_v2.asm
iverilog -o tb_cpu_v2_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v tb_cpu_v2.v
vvp tb_cpu_v2_sim
```

→ `*** ISA v2 TESTS PASS ***`

### 부트 펌웨어 asm

```powershell
python tools\asm.py programs\boot.asm
```

### 모듈 단위 (1~5단계)

`iverilog -o tb_<name>_sim <mod>.v tb_<name>.v` → `vvp tb_<name>_sim`

---

## FPGA — Tang Nano 9K

### 툴·디바이스

| 항목 | 값 |
|------|-----|
| 툴 | **GOWIN EDA** (Education) |
| 보드 | Sipeed **Tang Nano 9K** |
| FPGA | **GW1NR-LV9QN88PC6/I5** (QN88P, Ver. C) |
| 클럭 | 27 MHz → `tangnano9k.sdc` |

**주의:** `GW1N-9` + LQ144 ≠ Tang Nano 9K. **GW1NR-9 + QN88** 사용.

### Gowin 프로젝트 파일

```
top_tangnano9k.v    (Top, UART + LED)
cpu.v, alu.v, pc.v, register16.v, ram_fpga.v, uart_tx.v
tangnano9k.cst
tangnano9k.sdc
```

**포함하지 않음:** `tb_*.v`, `ram.v`

### 빌드 순서

1. Top: `top_tangnano9k`  
2. **Add File** → `tangnano9k.sdc`  
3. **Configuration → Use DONE as regular IO** 체크  
4. **Synthesize** → **Place & Route**  
5. 산출: `impl/pnr/top_tangnano9k.fs`

상세: [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md)

### WARN TA1132 (`sys_clk` clock not created)

- **원인:** `.sdc` 없이 PnR 시 발생  
- **해결:** `tangnano9k.sdc` 를 프로젝트에 추가 후 Syn/PnR 재실행  
- **주의:** `create_clock ...` 는 **PowerShell 명령이 아님** — `.sdc` 파일로만 추가

### 프로그램 로딩

| 용도 | 방법 |
|------|------|
| 보드 boot | `ram_fpga.v` initial / `programs/boot.mi` |
| 시뮬 | `tb_cpu.v` 또는 `tb_cpu_all.v` |
| asm 작성 | `python tools\asm.py programs\demo.asm` |

---

## RAM (9K 용량)

| 모듈 | 크기 | 용도 |
|------|------|------|
| `ram.v` | 65536×16 | 시뮬 only (BSRAM 초과) |
| `ram_fpga.v` | 256×16 | CPU + FPGA |

---

## 문서 인덱스

| 문서 | 설명 |
|------|------|
| [ISA.md](ISA.md) | 명령어 집 |
| [programs/TEST_ALL.md](programs/TEST_ALL.md) | 전 opcode 테스트 |
| [FPGA_RTL_REVIEW.md](FPGA_RTL_REVIEW.md) | FPGA RTL 검토 |
| [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md) | Gowin IDE |
| [COMPLETION.md](COMPLETION.md) | 빠른 완성 |
| [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md) | 보드 10분 |

---

## 향후 확장 (선택)

- UART RX (pin 18)  
- PSRAM RAM 확장  
- VGA, SD 카드, OS, 파이프라인  

---

## 참고

- CPU 이름: **HAEUN-16**
- [Icarus Verilog](https://bleyer.org/icarus/)
- [Tang Nano 9K Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)

교육/개인 프로젝트용.
