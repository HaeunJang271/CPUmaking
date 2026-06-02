# HAEUN-16

Verilog-2001로 설계한 **16비트 CPU** 프로젝트입니다.  
합성 가능한 RTL과 모듈별 테스트벤치, ISA 문서, 통합 시뮬레이션까지 포함합니다.

---

## 프로젝트 목표

| 목표 | 상태 |
|------|------|
| 16비트 CPU 설계 | 완료 |
| Verilog 코드 작성 | 완료 |
| 시뮬레이션 성공 | 완료 (Icarus Verilog) |
| FPGA 이식 가능 구조 | 합성 가능 RTL 기준 충족 |
| VGA / 키보드 / OS 확장 | **향후 과제** (본 저장소 1~8단계 범위 밖) |

---

## 개발 규칙 (적용 내용)

1. 모듈별 개별 `.v` 파일
2. 모듈마다 독립 `tb_*.v` 테스트벤치
3. 소스/테스트벤치 주석 포함
4. 합성 가능 Verilog (Verilog-2001, SystemVerilog 미사용)
5. 단계별 검증 후 통합

---

## 폴더 구조

```
HAEUN16/
├── adder16.v          # 16비트 가산기
├── register16.v       # 16비트 레지스터
├── alu.v              # ALU
├── pc.v               # Program Counter
├── ram.v              # 64KB RAM (65536 x 16bit)
├── cpu.v              # CPU 통합
├── tb_adder16.v
├── tb_register16.v
├── tb_alu.v
├── tb_pc.v
├── tb_ram.v
├── tb_cpu.v           # CPU 통합 테스트
├── ISA.md             # 명령어 집합 아키텍처
└── README.md
```

시뮬레이션 실행 시 생성되는 `*_sim` 바이너리는 로컬 빌드 산출물입니다.

---

## 아키텍처 요약

```
┌─────────┐     ┌──────────────┐     ┌─────┐
│ PC      │────▶│ RAM (64KW)   │◀───▶│ CPU │
└─────────┘     └──────────────┘     │     │
                                     │ R0~R3
                                     │ ALU │
                                     └─────┘
```

- **명령어 길이:** 16 bit  
- **레지스터:** R0, R1, R2, R3 (각 16 bit)  
- **명령:** NOP, LOAD, STORE, ADD, SUB, AND, OR, XOR, JMP  
- **실행:** Fetch1 → Fetch2 → Execute (STORE는 추가 메모리 사이클)

자세한 인코딩·동작은 [ISA.md](ISA.md)를 참고하세요.

---

## 사전 요구 사항

- [Icarus Verilog](https://bleyer.org/icarus/) (Windows 설치 시 **Add to PATH** 권장)
- 설치 확인:

```powershell
iverilog -V
vvp -V
```

PATH가 안 잡히면 전체 경로 사용 (예: `C:\iverilog\bin\iverilog.exe`).

---

## 시뮬레이션 방법

작업 디렉터리:

```powershell
cd path\to\CPUmaking\HAEUN16
```

### 모듈 단위 테스트

| 단계 | 컴파일 | 실행 |
|------|--------|------|
| 1 가산기 | `iverilog -o tb_adder16_sim adder16.v tb_adder16.v` | `vvp tb_adder16_sim` |
| 2 레지스터 | `iverilog -o tb_register16_sim register16.v tb_register16.v` | `vvp tb_register16_sim` |
| 3 ALU | `iverilog -o tb_alu_sim alu.v tb_alu.v` | `vvp tb_alu_sim` |
| 4 PC | `iverilog -o tb_pc_sim pc.v tb_pc.v` | `vvp tb_pc_sim` |
| 5 RAM | `iverilog -o tb_ram_sim ram.v tb_ram.v` | `vvp tb_ram_sim` |

성공 시 콘솔에 `*** ALL TESTS PASS ***` 가 출력됩니다.

### CPU 통합 테스트 (8단계)

```powershell
iverilog -o tb_cpu_sim cpu.v alu.v pc.v ram.v register16.v tb_cpu.v
vvp tb_cpu_sim
```

**프로그램 (RAM 0~2):**

| 주소 | 명령 | 기계어 |
|------|------|--------|
| 0 | LOAD R0, 5 | `0x1005` |
| 1 | LOAD R1, 3 | `0x1403` |
| 2 | ADD R0, R1 | `0x3100` |

**기대 결과:** R0 = 8, R1 = 3

---

## 단계별 완료 현황

| 단계 | 산출물 | 설명 |
|------|--------|------|
| 1 | `adder16.v` | 16비트 가산기 |
| 2 | `register16.v` | 동기 레지스터 |
| 3 | `alu.v` | ADD/SUB/AND/OR/XOR, ZERO |
| 4 | `pc.v` | PC +1 / jump / reset |
| 5 | `ram.v` | 65536 word RAM |
| 6 | `ISA.md` | 명령어 형식 정의 |
| 7 | `cpu.v` | CPU 통합 |
| 8 | `tb_cpu.v` | 통합 시뮬레이션 |

**계획된 1~8단계는 모두 완료되었습니다.**

---

## 향후 확장 아이디어 (선택)

본 README 범위 밖의 후속 작업 예시:

- **FPGA:** Vivado / Quartus에 RTL 합성, 제약·타이밍 검증
- **I/O:** VGA, PS/2 키보드용 메모리 맵 I/O · 추가 opcode
- **소프트웨어:** 어셈블러, 간단한 모니터/OS
- **성능:** 파이프라인, Harvard 구조(명령/데이터 메모리 분리)
- **도구:** GTKWave 파형, CI에서 `iverilog` 자동 실행

---

## 라이선스

교육/개인 프로젝트용. 상업 사용 시 각 컴포넌트 라이선스를 별도 확인하세요.

---

## 참고

- 명령어 상세: [ISA.md](ISA.md)
- CPU 이름: **HAEUN-16**
