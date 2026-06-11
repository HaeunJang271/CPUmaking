# HAEUN-16

Verilog-2001 기반 **16비트 CPU** 프로젝트.  
RTL · ISA v2 · 시뮬 · **HAEUN-OS v0.1** (UART + HDMI 셸) · Tang Nano 9K **LED / UART / HDMI SOC 실기** 까지 완료.

---

## 현재 상태

| 구분 | 상태 |
|------|------|
| CPU 코어 (1~8단계) | 완료 |
| ISA v2 (JZ / CALL / RET / OUT / IN) | 완료 |
| 시뮬 (`tb_cpu`, `tb_cpu_all`, `tb_cpu_v2`, `tb_os`) | **PASS** |
| UART TX/RX + FIFO | RTL + 시뮬 PASS |
| **HAEUN-OS v0.1** (`programs/os.asm`) | 시뮬 **PASS** · SOC 실기 **PASS** |
| **HAEUN16_SOC** (CPU + UART + LED + HDMI) | **실기 PASS** |
| **HDMI Phase 2** — RAM[247+] → 화면 `READY` | **실기 PASS** |
| **HDMI 부트 로고** — PNG 비트맵 오버레이 (`svo_bitmap_logo`) | RTL 완료 |
| `HAEUN16_9K` (CPU + LED + UART only) | 완료 |
| `HAEUN16_HDMI` (컬러바 + 정적 텍스트 only) | 컬러바 실기 PASS |

```text
RTL + 시뮬 + OS         ████████████████████  100%
HAEUN16_SOC (통합)      ████████████████████  100%  ← 권장 비트스트림
HDMI RAM 미러 (Phase 2) ████████████████████  100%
HAEUN16_9K (UART only)  ████████████████████  100%
HAEUN16_HDMI (단독)     ████████████████████  100%
```

### 한 줄 답

| 질문 | 답 |
|------|-----|
| CPU 만들었나? | **예** — RTL + 시뮬 PASS |
| FPGA에서 돌아가나? | **예** — `HAEUN16_SOC` Program 기준 |
| OS 만들었나? | **예** — HAEUN-OS v0.1, UART 셸 + HDMI 동시 출력 |
| HDMI 됐나? | **예** — 컬러바 + CPU 텍스트 + RAM 미러 `READY` |
| 어떤 프로젝트 쓰나? | **`HAEUN16_SOC`** (CPU·UART·HDMI 한 번에) |

---

## HAEUN16_SOC (권장)

CPU · UART · LED · HDMI를 **한 비트스트림**으로 통합한 top입니다.

### 기대 동작 (실기 확인됨)

| 출력 | 내용 |
|------|------|
| **HDMI** | 컬러바 + **비트맵 `HAEUN-OS` 로고** + `v0.1` / `READY` / `> ` |
| **UART** | `HAEUN-OS v0.1` / `> ` (`READY`는 UART에 **없음** — RAM 전용) |
| **LED** | 부팅 중 `~r0[5:0]` 패턴 → 완료 후 **6개 ON** (`R1=1`) |

```text
[ HAEUN-OS ]     ← FPGA 고정 비트맵 로고 (assets/haeun_os_logo.png)
v0.1
READY

> 
```

### 빌드 · Program

```powershell
cd path\to\CPUmaking\HAEUN16
powershell -File tools\sync_soc_gowin.ps1
python tools\gen_ram_os.py          # sync 스크립트가 자동 호출함
python tools\gen_bitmap_logo.py     # 로고 PNG 변경 시 (ROM .vh 재생성)
```

1. Gowin `Documents\HAEUN16_SOC\HAEUN16_SOC.gprj` 열기
2. **Project → Reload All** (필수 — 새 `.v` / FileList 갱신)
3. Top module: **`top_haeun16_soc`**
4. **Synthesize → Place & Route → Generate Bitstream → Program**
5. HDMI 케이블 + UART 115200 8N1

> `sync_soc_gowin.ps1`은 `impl/gwsynthesis/` 캐시를 삭제합니다.  
> `unknown module` (EX3937) 이 나면 **Reload All** 후 재합성.  
> `screen_from_ram` · `svo_bitmap_logo`는 `svo_hdmi_soc.v`의 `` `include `` 로만 포함 — **`.gprj` FileList에 따로 넣지 말 것** (중복·`initial` 오류 방지).

### SOC 아키텍처

```text
CPU @ 27MHz ── OUT port 0 ──► UART TX/RX
            ── OUT port 1 ──► screen_io_tx ──► screen_ram ──► HDMI 텍스트
            ── OUT port 2 ──► HDMI 커서 (다음 글자 위치)
            ── STORE 0x80+ ─► screen_ram (직접 쓰기)
            ── RAM 247+    ─► screen_from_ram (peek → 화면 미러)

PLL ──► 640×480 HDMI (컬러바 + 비트맵 로고 + svo_live_text 오버레이)
```

| 모듈 | 역할 |
|------|------|
| `top_haeun16_soc.v` | CPU + UART + LED + `svo_hdmi_soc` |
| `screen_ram.v` | 듀얼클럭 텍스트 버퍼 (쓰기=sys_clk, 읽기=pix_clk) |
| `screen_bridge.v` | 스트림 / STORE / RAM미러 mux |
| `screen_from_ram.v` | RAM[247+] → screen_ram[14+] 1회 미러 |
| `screen_io_tx.v` | OUT port 1 스트림 (CR 제외) |
| `hdmi_colorbars/src/svo_hdmi_soc.v` | 컬러바 + 로고 + CPU 연동 HDMI top |
| `hdmi_colorbars/src/hdmi/svo_bitmap_logo.v` | PNG → 1bpp ROM 오버레이 (Gowin `localparam` ROM) |

### I/O · 메모리 맵

| 대상 | 설명 |
|------|------|
| **port 0** | UART TX (`OUT`) / RX (`IN`) |
| **port 1** | HDMI 문자 스트림 (`SEND` 매크로 = UART + HDMI 동시) |
| **port 2** | HDMI 커서 — `OUT R0, 2` → `R0[5:0]` = 다음 글자 슬롯 |
| **RAM 0~246** | 프로그램 · 데이터 |
| **RAM 247+** | HDMI 미러용 문자열 (`STORE_READY` → `"READY\0"`) |
| **0x80~0xBF** | `STORE` → `screen_ram` 직접 쓰기 (Phase 3) |

상세: [ISA.md](ISA.md) § I/O map

### HDMI Phase 요약

| Phase | 내용 | 상태 |
|-------|------|------|
| 컬러바 | `HAEUN16_HDMI`, SMPTE 패턴 | 실기 PASS |
| Phase 1 | `screen_status.v` — R0/R1/PC 덤프 (RTL) | SOC 미사용 |
| Phase 2 | RAM[247+] → HDMI `READY` | **실기 PASS** |
| Phase 3 | `STORE 0x80+` → 화면 | RTL 완료 |
| Phase 4 | `OUT port 1` — OS `SEND` → HDMI | **실기 PASS** |

---

## HAEUN-OS v0.1

모놀리식 UART + HDMI 셸 (`programs/os.asm`, ~278 word, `ram_fpga` 512 word).

```text
HAEUN-OS v0.1
> help
help echo version reboot
> version
v0.1
> echo hi
 hi
> reboot
(재부팅)
```

| 명령 | 설명 |
|------|------|
| `help` | 명령 목록 출력 |
| `version` | `v0.1` 한 줄 출력 |
| `echo <text>` | 공백 뒤 문자열 에코 |
| `reboot` | 부트 배너부터 재시작 |

### 키보드 입력 (UART RX → HDMI 에코)

PC 시리얼 터미널 → pin 18 `uart_rx` → `IN port 0` → **`RECV`가 UART·HDMI 동시 에코**.

| 항목 | 설명 |
|------|------|
| 수신 | FIFO 비면 `RECV` 대기 (`JZ` 루프) |
| 에코 | `SEND` = port 0 + port 1 |
| Enter | CR(`13`) → LF(`10`) 변환 (HDMI는 CR 미표시) |

```text
> help          ← 입력 글자가 HDMI에도 표시
help echo version reboot
```

RX 미동작 시: [BL702_ONBOARD.md](fpga/BL702_ONBOARD.md) usb2uartjtag 펌웨어 또는 pin 18 USB-TTL.

부팅 시 (`os.asm`):

1. `SEND_UART` — UART에만 전체 `HAEUN-OS v0.1`
2. `SEND` — `v0.1` → UART + HDMI (로고는 RTL 고정, HDMI에는 버전만)
3. HDMI 빈 줄 — 로고 높이만큼 `\n` (`LOAD R2, 12` 등, 로고 크기에 맞게 조정)
4. `STORE_READY` — RAM[247..252] ← `"READY\0"`
5. `R1=1` — LED 완료 + `screen_from_ram` 미러 트리거
6. `WAIT_MIRROR` — 미러 FSM 완료 대기
7. HDMI 빈 줄 2개 + 커서 21 → `> ` 프롬프트

| 파일 | 역할 |
|------|------|
| `programs/os.asm` | 셸 + HDMI 부트 |
| `tools/gen_ram_os.py` | `os.asm` → `ram_fpga.v` initial |
| `tools/gen_bitmap_logo.py` | `assets/haeun_os_logo.png` → `svo_bitmap_logo_rom.vh` |
| `tools/asm.py` | 어셈블러 |
| `tb_os.v` | 부트 + help/version/echo 시뮬 |

```powershell
python tools\gen_ram_os.py
# 또는
python tools\asm.py programs\os.asm --verilog

iverilog -o tb_os_sim cpu.v alu.v pc.v ram_fpga.v register16.v ^
  uart_tx.v uart_rx.v uart_fifo_tx.v uart_fifo_rx.v tb_os.v
vvp tb_os_sim
# 기대: *** HAEUN-OS TEST PASS ***
```

---

## 보드 실기

### LED (`top_tangnano9k` / `top_haeun16_soc` 공통)

| 단계 | LED | 의미 |
|------|-----|------|
| 부팅 중 | 패턴 변화 | CPU 실행 (`~r0[5:0]`) |
| boot 완료 | **6개 ON** | `R1=1` |

### UART

→ **[UART_TX.md](UART_TX.md)** — BL702 온보드 또는 pin 37 USB-TTL, **115200 8N1**

### HDMI (단독 컬러바 테스트)

→ **[hdmi_colorbars/HDMI_COLORBARS.md](hdmi_colorbars/HDMI_COLORBARS.md)**

```powershell
powershell -File tools\sync_hdmi_gowin.ps1
# HAEUN16_HDMI.gprj → top_hdmi_colorbars
```

재현 절차: **[BOARD_QUICKSTART.md](BOARD_QUICKSTART.md)**

---

## Gowin 프로젝트

| 프로젝트 | Top | 용도 |
|----------|-----|------|
| **`HAEUN16_SOC`** | `top_haeun16_soc` | **CPU + UART + LED + HDMI (권장)** |
| `HAEUN16_9K` | `top_tangnano9k` | CPU + UART + LED only |
| `HAEUN16_HDMI` | `top_hdmi_colorbars` | HDMI 컬러바 + 정적 텍스트 only |

| 동기화 스크립트 | 대상 |
|----------------|------|
| `tools\sync_soc_gowin.ps1` | `HAEUN16_SOC` |
| `tools\sync_gowin.ps1` | `HAEUN16_9K` |
| `tools\sync_hdmi_gowin.ps1` | `HAEUN16_HDMI` |

> repo `HAEUN16/` 와 Gowin `Documents\*\src\` 는 **별도 복사본**. RTL 수정 후 해당 sync 스크립트 필수.  
> 한 번에 **하나의 `.gprj`만** Program.

### 자주 나는 Gowin 메시지

| 메시지 | 원인 | 해결 |
|--------|------|------|
| `EX3937` unknown module | stale `.prj` / Reload 안 함 | `sync_*` → **Reload All** → 재합성 |
| `EX3863` / `EX2656` `initial` in `.vh` | ROM `.vh`를 FileList에 중복 등록 | FileList에서 `svo_bitmap_logo*.vh` 제거, `gen_bitmap_logo.py` 재실행 |
| `EX3794` duplicate module | `.v` + `` `include `` 이중 등록 | `svo_bitmap_logo.v`는 include만 사용 |
| `PA2122` DPB WRITE_MODE | 듀얼포트 RAM RBW | `ram_fpga.v` write-through 패턴 (SOC 반영됨) |
| `EX3990` 포트 불일치 | 구버전 `cpu.v` | sync 후 Reload |
| `TA1132` sys_clk | `.sdc` 미등록 | `.gprj` FileList 확인 |

---

## 폴더 구조

```text
HAEUN16/
├── assets/
│   └── haeun_os_logo.png      # HDMI 부트 비트맵 로고 원본
├── cpu.v, alu.v, pc.v, register16.v
├── ram.v                      # 65536 word (시뮬 전용)
├── ram_fpga.v                 # 512 word + os.asm initial
├── uart_*.v, uart_path_bl702.v, bl702_boot_delay.v
├── top_tangnano9k.v           # HAEUN16_9K
├── top_haeun16_soc.v          # HAEUN16_SOC
├── screen_ram.v, screen_bridge.v, screen_from_ram.v
├── screen_io_tx.v, screen_status.v
├── soc/
│   ├── HAEUN16_SOC.gprj
│   └── tangnano9k_soc.cst
├── hdmi_colorbars/            # HDMI RTL + HAEUN16_HDMI.gprj
│   ├── src/svo_hdmi_soc.v
│   ├── src/hdmi/svo_bitmap_logo.v
│   └── HDMI_COLORBARS.md
├── tools/
│   ├── asm.py
│   ├── gen_ram_os.py
│   ├── gen_bitmap_logo.py
│   ├── sync_gowin.ps1
│   ├── sync_hdmi_gowin.ps1
│   └── sync_soc_gowin.ps1
├── programs/os.asm
├── tb_os.v, tb_*.v
└── ISA.md, UART_TX.md, ...
```

---

## 아키텍처 (CPU only)

```text
                    ┌─────────────┐
  27MHz ───────────▶│ top         │──▶ LED[5:0]
                    │             │──▶ uart_tx / uart_rx
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │ cpu (HAEUN-16)        │
              │  R0~R3, ALU, PC, FSM  │
              └────────────┬──────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │ ram_fpga 512×16 + peek port       │
         │ os.asm (HAEUN-OS v0.1)            │
         └───────────────────────────────────┘
         OUT port 0 → UART
         OUT port 1 → HDMI stream (SOC)
         OUT port 2 → HDMI cursor (SOC)
```

| 항목 | 내용 |
|------|------|
| 명령어 | NOP, LOAD, STORE, ADD, SUB, AND, OR, XOR, JMP, JZ, CALL, RET, OUT, IN |
| I/O | port 0 UART · port 1 HDMI stream · port 2 HDMI cursor |

---

## 시뮬레이션 (Icarus Verilog)

```powershell
cd path\to\CPUmaking\HAEUN16
```

### HAEUN-OS (셸)

```powershell
python tools\gen_ram_os.py
iverilog -o tb_os_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v uart_rx.v uart_fifo_tx.v uart_fifo_rx.v tb_os.v
vvp tb_os_sim
```

### demo / opcode / v2 / UART

```powershell
iverilog -o tb_cpu_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu.v
python tools\asm.py programs\test_all.asm
iverilog -o tb_cpu_all_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu_all.v
python tools\asm.py programs\test_v2.asm
iverilog -o tb_cpu_v2_sim cpu.v alu.v pc.v ram_fpga.v register16.v uart_tx.v tb_cpu_v2.v
```

---

## FPGA — Tang Nano 9K

| 항목 | 값 |
|------|-----|
| 툴 | GOWIN EDA (Education) 1.9.11 |
| FPGA | **GW1NR-LV9QN88PC6/I5** (QN88) |
| 클럭 | 27 MHz (sys), PLL → 25 MHz pixel (HDMI) |

### RAM

| 모듈 | 크기 | 용도 |
|------|------|------|
| `ram.v` | 65536×16 | 시뮬 only |
| `ram_fpga.v` | **512×16** | CPU + FPGA (프로그램 ~278 word) |

OS 갱신: `python tools\gen_ram_os.py` → `sync_soc_gowin.ps1` → Gowin 재합성

---

## 타임라인

| 단계 | 산출물 |
|------|--------|
| 1~8 | CPU 코어, ISA, 시뮬 |
| v2 | JZ/CALL/RET/OUT/IN, UART |
| OS | HAEUN-OS v0.1, `tb_os` PASS |
| FPGA | `HAEUN16_9K`, LED 실기 |
| HDMI | `HAEUN16_HDMI` 컬러바 실기 |
| **SOC** | `HAEUN16_SOC`, UART + HDMI 동시 출력 |
| **Phase 2** | RAM → HDMI `READY` 미러 실기 PASS |
| **Phase 4** | OS `SEND` → HDMI 터미널 실기 PASS |
| **부트 로고** | PNG 비트맵 `HAEUN-OS` HDMI 오버레이 |

### HDMI 부트 로고

| 항목 | 설명 |
|------|------|
| 원본 | `assets/haeun_os_logo.png` |
| 생성 | `python tools\gen_bitmap_logo.py` (`--scale 0.75` 기본, `--y0` 상단 여백) |
| RTL | `svo_bitmap_logo.v` + `svo_bitmap_logo_rom.vh` (`localparam` flat ROM — Gowin `initial` 미사용) |
| 합성 | **`.gprj`에 로고 파일 등록 금지** — `svo_hdmi_soc.v` `` `include `` 만 |

---

## 문서

| 문서 | 설명 |
|------|------|
| [ISA.md](ISA.md) | 명령어 · I/O · 화면 메모리 맵 |
| [UART_TX.md](UART_TX.md) | PC 터미널 UART |
| [hdmi_colorbars/HDMI_COLORBARS.md](hdmi_colorbars/HDMI_COLORBARS.md) | HDMI 단독 빌드 |
| [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md) | 보드 10분 |
| [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md) | Gowin IDE |
| [fpga/BL702_ONBOARD.md](fpga/BL702_ONBOARD.md) | 온보드 BL702 |

---

## 다음 작업 (선택)

- Phase 3 실기 — `STORE 0x80+` 화면 직접 쓰기 검증
- README 외 `HDMI_COLORBARS.md` SOC 크로스링크
- PSRAM / SD / 인터럽트

---

## 참고

- [Icarus Verilog](https://bleyer.org/icarus/)
- [Tang Nano 9K Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)
- [Coddy ASCII 아트 생성기](https://coddy.tech/tools/ko/ascii-art-generator) — 텍스트·이미지 → ASCII 아트 (로고·배너 아이디어 참고)

교육/개인 프로젝트.
