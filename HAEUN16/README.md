# HAEUN-16

Verilog-2001로 설계한 **16비트 CPU** 프로젝트입니다.  
모듈별 테스트벤치·ISA·통합 시뮬레이션, **Tang Nano 9K(GW1NR-9)** FPGA 이식 준비까지 포함합니다.

---

## 프로젝트 목표

| 목표 | 상태 |
|------|------|
| 16비트 CPU 설계 | 완료 |
| Verilog RTL 작성 | 완료 |
| 시뮬레이션 검증 | 완료 (Icarus Verilog) |
| ISA 문서 | 완료 (`ISA.md`) |
| FPGA 이식 RTL | 완료 (`ram_fpga`, `top_tangnano9k`, `.cst`) |
| Gowin 합성·Place & Route | 완료 (사용자 환경, `GW1NR-LV9QN88PC6/I5`) |
| FPGA 보드 실기 동작 | **대기** — Program Device + LED 확인 |
| VGA / 키보드 / OS | **향후 과제** |

### CPU를 만들었나? / FPGA에서 돌아가나?

| 질문 | 답 |
|------|-----|
| CPU를 만들었나? | **예.** 1~8단계 RTL + `tb_cpu` PASS (R0=8) |
| FPGA 비트스트림? | **예.** Gowin Synthesize + PnR 완료 (보드 없이 가능한 범위) |
| 보드에서 확인? | **아직.** USB 다운로드 후 LED 6개 ON = 최종 완성 |

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
| 6 | `ISA.md` | 16bit 명령어·레지스터 R0~R3 |
| 7 | `cpu.v` | Fetch1→Fetch2→Exec, 9개 opcode |
| 8 | `tb_cpu.v` | LOAD/ADD 프로그램 → **R0=8** PASS |

### FPGA (Tang Nano 9K)

| 단계 | 산출물 | 내용 |
|------|--------|------|
| 준비 | Gowin EDA (Education) | Tang Nano 9K, **라이선스 불필요** |
| 2 | [FPGA_RTL_REVIEW.md](FPGA_RTL_REVIEW.md) | `cpu`/`ram`/`tb_cpu` FPGA 관점 검토 |
| 3 | `ram_fpga.v`, `program.mi` | 256×16 RAM (9K BSRAM 용량), 프로그램 init |
| 3 | `cpu.v` | 내부 RAM → `ram_fpga` |
| 4 | `top_tangnano9k.v`, `tangnano9k.cst` | 27MHz, 버튼 리셋, LED |
| 4 | [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md) | Gowin 프로젝트·빌드 방법 |
| 5 | Gowin 프로젝트 `HAEUN16_9K` | Device **GW1NR-LV9QN88PC6/I5**, **Synthesize + PnR** |
| 완성 보조 | [COMPLETION.md](COMPLETION.md), [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md) | 빠른 완성·보드 10분 가이드 |
| 도구 | `tools/asm.py`, `programs/demo.asm` | 어셈블리 → hex / `.mi` |

### `top_tangnano9k` LED (보드 확인용)

- **PASS 조건:** R0=8 이고 R1=3 → **LED 6개 전부 ON** (active-low `000000`)
- top 수정 후 **Gowin에서 PnR 한 번 더** 실행 권장 (최신 `.fs`)

---

## 현재 위치

```text
CPU 설계·RTL·시뮬     완료
ISA                  완료
ram_fpga + top + cst 완료
Gowin PnR            완료
보드 Program + LED   대기
```

```text
CPU + 시뮬 + Gowin PnR    ███████████████████░  ~95%
보드 실기 확인            ░░░░░░░░░░░░░░░░░░░░   ~5%
```

---

## 폴더 구조

```
HAEUN16/
├── adder16.v, register16.v, alu.v, pc.v
├── ram.v                  # 65536 word (시뮬/교육, 9K BRAM 초과)
├── ram_fpga.v             # 256 word (FPGA/CPU 실제 사용)
├── cpu.v                  # CPU 통합 (ram_fpga)
├── top_tangnano9k.v       # Tang Nano 9K 탑
├── tangnano9k.cst         # 핀 제약
├── program.mi             # BRAM init hex
├── tb_*.v                 # 모듈·통합 테스트 (FPGA 빌드 제외)
├── ISA.md
├── FPGA_RTL_REVIEW.md
├── COMPLETION.md          # 빠른 완성 체크리스트
├── BOARD_QUICKSTART.md    # 보드 도착 후 10분
├── fpga/GOWIN_PROJECT.md
├── tools/asm.py
├── programs/demo.asm
├── programs/test_all.asm
├── tb_cpu_all.v
└── README.md
```

Gowin 프로젝트(별도 경로 예): `HAEUN16_9K/` — `.gprj`, `impl/pnr/*.fs`  
시뮬 산출물: `*_sim` (git 제외 권장)

---

## 개발 규칙 (적용 내용)

1. 모듈별 개별 `.v` 파일  
2. 모듈마다 독립 `tb_*.v`  
3. 주석 포함 (콘솔 메시지는 영문 — 인코딩 깨짐 방지)  
4. Verilog-2001, 합성 가능 RTL  
5. 단계별 검증 후 통합  

---

## 아키텍처 요약

```
┌─────────┐     ┌──────────────┐     ┌─────────────┐
│ PC      │────▶│ ram_fpga     │◀───▶│ cpu         │
└─────────┘     │ 256×16bit    │     │ R0~R3, ALU  │
                └──────────────┘     └─────────────┘
```

- **명령:** NOP, LOAD, STORE, ADD, SUB, AND, OR, XOR, JMP  
- **사이클:** Fetch1 → Fetch2 → Execute (STORE +1)  
- 상세: [ISA.md](ISA.md)

---

## 시뮬레이션 (Icarus Verilog)

```powershell
cd path\to\CPUmaking\HAEUN16
iverilog -V
```

### 모듈 단위

| 단계 | 실행 |
|------|------|
| 1~5 | `iverilog -o tb_*_sim <모듈>.v tb_*.v` → `vvp tb_*_sim` |

### CPU 통합

```powershell
iverilog -o tb_cpu_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu.v
vvp tb_cpu_sim
```

### 전 opcode 테스트

```powershell
python tools\asm.py programs\test_all.asm
iverilog -o tb_cpu_all_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu_all.v
vvp tb_cpu_all_sim
```

→ `*** ALL OPCODE TESTS PASS ***` (NOP, LOAD, ADD, SUB, AND, OR, XOR, STORE, JMP)  
상세: [programs/TEST_ALL.md](programs/TEST_ALL.md)

| 주소 | 명령 | Hex |
|------|------|-----|
| 0 | LOAD R0, 5 | `1005` |
| 1 | LOAD R1, 3 | `1403` |
| 2 | ADD R0, R1 | `3100` |

**기대:** R0=8, R1=3, `*** ALL TESTS PASS ***`

### 어셈블러 (선택)

```powershell
python tools\asm.py programs\demo.asm
```

---

## FPGA — Tang Nano 9K

### 툴·디바이스

| 항목 | 값 |
|------|-----|
| 툴 | **GOWIN EDA** (Education, 라이선스 불필요) |
| 보드 | Sipeed **Tang Nano 9K** |
| FPGA | **GW1NR-LV9QN88PC6/I5** (QN88P, Version C) |
| 클럭 | 27 MHz (pin 52) |

**주의:** `GW1N-9` + LQ144 는 **다른 칩** — 반드시 **GW1NR-9 + QN88**.

### Gowin 프로젝트에 넣을 파일

```
top_tangnano9k.v   (Top)
cpu.v, alu.v, pc.v, register16.v, ram_fpga.v
tangnano9k.cst
```

**넣지 않음:** `tb_*.v`, `ram.v`

### 빌드 (USB 불필요)

1. Top: `top_tangnano9k`  
2. **Configuration → Use DONE as regular IO** 체크  
3. **Synthesize** → **Place & Route**  
4. 산출: `impl/pnr/top_tangnano9k.fs`

자세한 절차: [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md)

### 프로그램 로딩

| 환경 | 방법 |
|------|------|
| 시뮬 | `tb_cpu` → `uut.u_ram.memory[...]` 또는 `ram_fpga` initial |
| FPGA | `ram_fpga.v` **initial** / `program.mi` |

### 보드 도착 후 (최종 완성)

→ [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md)

1. USB → **Program Device** → `top_tangnano9k.fs`  
2. **S1** 버튼 눌렀다 떼기  
3. **LED 6개 ON** → 프로젝트 완료  

빠른 체크리스트: [COMPLETION.md](COMPLETION.md)

---

## RAM 용량 (9K)

| 모듈 | 크기 | 용도 |
|------|------|------|
| `ram.v` | 65536×16 (1024 Kbit) | 시뮬 only — 9K BSRAM(468K) 초과 |
| `ram_fpga.v` | 256×16 (4 Kbit) | CPU + FPGA |

---

## 향후 확장 (선택)

- UART 디버그 (FPGA pin 17/18)  
- PSRAM으로 RAM 확장  
- VGA, 키보드, OS, 파이프라인  

---

## 문서 인덱스

| 문서 | 설명 |
|------|------|
| [ISA.md](ISA.md) | 명령어 집 |
| [FPGA_RTL_REVIEW.md](FPGA_RTL_REVIEW.md) | FPGA RTL 검토 |
| [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md) | Gowin IDE 설정 |
| [COMPLETION.md](COMPLETION.md) | 빠른 완성 로드맵 |
| [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md) | 보드 10분 |

---

## 라이선스

교육/개인 프로젝트용.

---

## 참고

- CPU 이름: **HAEUN-16**
- Icarus: [bleyer.org/icarus](https://bleyer.org/icarus/)
- Tang Nano 9K: [Sipeed Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)
