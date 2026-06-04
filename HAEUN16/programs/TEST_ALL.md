# test_all — 전 opcode 테스트 프로그램

## 파일

| 파일 | 설명 |
|------|------|
| `test_all.asm` | 소스 (주석 포함) |
| `test_all.mi` | `asm.py` 생성 hex (20 words) |
| `tb_cpu_all.v` | 시뮬 검증 |

## opcode 커버리지

| Addr | 명령 | 검증 내용 |
|------|------|-----------|
| 0 | NOP | 실행만 (파이프라인 통과) |
| 1-2 | LOAD | R0=10, R1=3 |
| 3 | ADD | R0=13 |
| 4 | SUB | R0=10 |
| 5-7 | LOAD+AND | R2=0xAA&0x55=0 |
| 8-10 | LOAD+OR | R2=0x0F\|0xF0=255 |
| 11-13 | LOAD+XOR | R2=0xAA^0x55=255 |
| 4 | SUB | R0=10 (13-3) |
| 14 | STORE R1,32 | RAM[32]=3 (R1 아직 3) |
| 15 | JMP 18 | addr 16-17 스킵 |
| 18-19 | LOAD | R0=99, R1=1 |

## 종료 시 기대값

| 항목 | 값 |
|------|-----|
| R0 | 99 |
| R1 | 1 |
| R2 | 255 |
| R3 | 85 |
| RAM[32] | 3 |

## 시뮬레이션

```powershell
cd HAEUN16
python tools\asm.py programs\test_all.asm
iverilog -o tb_cpu_all_sim cpu.v alu.v pc.v ram_fpga.v register16.v tb_cpu_all.v
vvp tb_cpu_all_sim
```

## FPGA

`demo.asm` 대신 RAM init 에 `test_all.mi` 내용을 넣으면 보드에서도 동일 테스트 가능 (LED는 `top` done 조건이 R0=8 이므로 별도 top 수정 필요).
