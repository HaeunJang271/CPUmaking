# FPGA RTL 검토 (2단계) — Tang Nano 9K

`cpu.v`, `ram.v`, `tb_cpu.v`를 **FPGA 이식 관점**에서 검토한 결과입니다.  
**결론:** CPU 로직은 그대로 쓸 수 있고, **RAM 크기·프로그램 로딩·탑 모듈**만 FPGA용으로 따로 준비하면 됩니다.

---

## 검토 요약

| 파일 | 시뮬 | FPGA | 조치 |
|------|------|------|------|
| `cpu.v` | OK | **대체로 OK** | RAM 모듈만 `ram_fpga`로 교체 (3단계) |
| `ram.v` | OK | **9K에 부적합** | `ram_fpga.v` 신규 (256 word) |
| `tb_cpu.v` | OK | **사용 안 함** | Gowin 프로젝트에 넣지 않음 |

---

## 1. `cpu.v`

### 1.1 외부 포트 (탑에서 연결할 신호)

| 포트 | 방향 | FPGA top에서 |
|------|------|----------------|
| `clk` | input | 보드 27MHz (또는 PLL/분주 후) |
| `reset` | input | 버튼 → **동기 리셋**으로 변환 권장 |
| `r0`~`r3` | output | LED / UART 디버그 |
| `pc_out` | output | (선택) 디버그 |

`cpu`는 **클럭·리셋만** 있으면 동작합니다. 별도 메모리 버스 포트 없음 (RAM 내부 인스턴스).

### 1.2 내부 구조 (합성 관점)

| 블록 | 인스턴스 | FPGA |
|------|----------|------|
| 레지스터 | `register16` × 4 | FF로 합성 |
| ALU | `alu` | 조합 논리 |
| PC | `pc` | FF + 증가기 |
| RAM | `ram u_ram` | **여기가 문제** → `ram_fpga`로 교체 |
| FSM | `state` 2bit | 4상태, 문제 없음 |

### 1.3 실행 타이밍 (FPGA에서도 동일)

한 명령당 대략 **3~4 클럭** (STORE는 +1):

```text
ST_FETCH1 → ST_FETCH2 → ST_EXEC → (ST_STORE)
```

- **Fetch1:** `mem_addr = pc_out`, RAM 읽기 시작  
- **Fetch2:** `ir <= mem_rdata`  
- **EXEC:** 레지스터 writeback, PC+1 또는 JMP  
- **STORE:** `mem_addr = {8'b0, imm8}`, `mem_we=1`

### 1.4 RAM 인터페이스 (3단계에서 바꿀 부분)

```167:173:c:\Users\level\OneDrive\Desktop\Projects\CPUmaking\HAEUN16\cpu.v
    ram u_ram (
        .clk          (clk),
        .write_enable (mem_we),
        .address      (mem_addr),
        .data_in      (mem_wdata),
        .data_out     (mem_rdata)
    );
```

- 포트 이름·폭은 **`ram_fpga`와 동일**하게 유지하면 `cpu.v` 수정 최소화  
- `address[15:0]`는 그대로 두고, `ram_fpga` 내부에서 **하위 8비트만** 사용 (256 word)

### 1.5 주의 (치명적이지 않음)

| 항목 | 내용 |
|------|------|
| `read_reg` function | Gowin에서 합성 가능 (MUX) |
| `alu_zero` | 현재 CPU FSM에서 미사용 — 무시 OK |
| `reset` | **높을 때 리셋** (`reset=1` → state 0). top에서 버튼(active-low) 변환 필요 |

### 1.6 FPGA 수정 예정 (3단계 이후)

```verilog
// cpu.v 167행 부근 — 모듈 이름만 변경
ram_fpga u_ram ( ... );   // 기존 ram → ram_fpga
```

---

## 2. `ram.v`

### 2.1 용량 — Tang Nano 9K와 맞지 않음

| 항목 | 값 |
|------|-----|
| 현재 RAM | 65536 × 16 bit = **1,048,576 bit (1024 Kbit)** |
| GW1NR-9 BSRAM 전체 | **468 Kbit** |
| 판정 | **그대로 합성 불가** (BRAM 초과) |

### 2.2 시뮬 전용 `initial` 블록

```25:28:c:\Users\level\OneDrive\Desktop\Projects\CPUmaking\HAEUN16\ram.v
    initial begin
        for (i = 0; i < 65536; i = i + 1)
            memory[i] = 16'h0000;
    end
```

- **Icarus:** OK  
- **FPGA:** 대용량 `initial` 비권장 → **Gowin .mi 초기화** 또는 `ram_fpga` + 작은 init

### 2.3 동작 (cpu와 맞음 — 유지할 패턴)

- 동기 읽기: 주소 설정 후 **다음 `posedge clk`에 `data_out` 유효**  
- Fetch1→Fetch2 2사이클 Fetch와 **일치** → `ram_fpga`도 동일 인터페이스 유지

### 2.4 2단계 결정 (확정)

```text
Tang Nano 9K 1차 목표: ram_fpga = 256 word × 16 bit
```

| 이유 | |
|------|--|
| 테스트 프로그램 | 주소 0~2만 사용 |
| ISA STORE/LOAD imm8 | 주소 0~255 |
| BRAM | 4 Kbit → 468 Kbit 안에 여유 |

**`ram.v`는 시뮬/교육용으로 유지**, FPGA 빌드에는 **`ram_fpga.v`만 추가**.

---

## 3. `tb_cpu.v`

### 3.1 시뮬 전용 — FPGA에 쓰면 안 되는 이유

```49:51:c:\Users\level\OneDrive\Desktop\Projects\CPUmaking\HAEUN16\tb_cpu.v
            uut.u_ram.memory[0] = 16'h1005;
            uut.u_ram.memory[1] = 16'h1403;
            uut.u_ram.memory[2] = 16'h3100;
```

| 문제 | 설명 |
|------|------|
| 계층 참조 | `uut.u_ram.memory` — 합성/구현 대상 아님 |
| 테스트벤치 | Gowin 프로젝트 **소스에 포함하지 않음** |

### 3.2 FPGA에서 같은 프로그램 넣는 방법

| 주소 | Hex | 명령 |
|------|-----|------|
| 0 | `1005` | LOAD R0, 5 |
| 1 | `1403` | LOAD R1, 3 |
| 2 | `3100` | ADD R0, R1 |

→ **3단계:** `program.mi` 또는 `ram_fpga` init 파일  
→ **8단계 시뮬:** `tb_cpu.v` + `ram.v` 그대로 유지

### 3.3 tb에만 있는 것 (FPGA 불필요)

- `$display`, `$finish`, `repeat`, `#delay`  
- `cycle_count` 로그

---

## 4. Tang Nano 9K 체크리스트 (2단계 결과)

- [x] `cpu.v` — top에서 `clk`/`reset` 연결, `r0`→LED 가능  
- [x] `ram.v` — 64KW는 9K 부적합 → **256W `ram_fpga` 확정**  
- [x] `tb_cpu.v` — FPGA 빌드 제외, 프로그램은 init 파일로 이전  
- [x] `ram_fpga.v` 작성 + `cpu.v` 교체 → **3단계 완료**  
- [x] `top_tangnano9k.v` + `tangnano9k.cst` → **4단계 완료**

---

## 5. 3단계 완료 내역

| 파일 | 내용 |
|------|------|
| `ram_fpga.v` | 256×16, `initial` + 주소 `[7:0]` |
| `cpu.v` | `ram_fpga u_ram` 인스턴스 |
| `program.mi` | Gowin BRAM init용 hex (`1005`, `1403`, `3100`) |

시뮬: `iverilog ... ram_fpga.v` 로 `tb_cpu` **PASS** 확인.

## 6. 4단계 완료 / 다음 (5단계)

- [x] `top_tangnano9k.v` — 27MHz, 동기 리셋, `led = ~r0[5:0]`  
- [x] `tangnano9k.cst` — clk 52, rst 4, LED 10~16  
- [ ] Gowin 합성·다운로드 → [fpga/GOWIN_PROJECT.md](fpga/GOWIN_PROJECT.md)  

---

## 7. 한 줄 결론

> **CPU(`cpu.v`)는 FPGA에 올릴 준비가 됐고, RAM(`ram.v`)과 테스트(`tb_cpu.v`) 방식만 FPGA용으로 갈아끼우면 된다.**
