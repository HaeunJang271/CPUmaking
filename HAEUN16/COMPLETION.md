# HAEUN-16 빠른 완성 로드맵

**목표:** 보드 없이 최대한 끝내고, 보드는 **10분 검증**만.

---

## 완성 기준 (2줄)

| 단계 | 기준 | 상태 |
|------|------|------|
| A. 소프트웨어 | `tb_cpu` PASS + Gowin PnR OK | **완료 가능** |
| B. 하드웨어 | 리셋 후 **LED 6개 ON** | 보드 필요 |

---

## 지금 당장 (보드 없음, 30분)

### 필수 3개

| # | 작업 | 시간 | 완료 |
|---|------|------|------|
| 1 | Gowin **Synthesize + PnR** | done | [ ] |
| 2 | `top_tangnano9k.v` **done LED** → **재 PnR** | 5분 | [ ] |
| 3 | `.fs` 백업 (`impl/pnr/`) | 1분 | [ ] |

### 권장 2개

| # | 작업 | 시간 |
|---|------|------|
| 4 | `python tools/asm.py programs/demo.asm` | 1분 |
| 5 | `iverilog` + `vvp tb_cpu_sim` 재확인 | 2분 |

### 하지 말 것 (완성 지연)

- VGA / PSRAM / 파이프라인
- CPU 대규모 수정
- 64KW `ram.v` FPGA 합성

---

## 보드 도착 (10분)

→ [BOARD_QUICKSTART.md](BOARD_QUICKSTART.md)

1. USB → Program Device → `.fs`
2. 버튼 리셋
3. **LED 6개 ON** = **프로젝트 완료**

---

## top 재빌드 이유

done LED 추가:

```verilog
wire done = (r0 == 16'd8) && (r1 == 16'd3);
assign led = done ? 6'b000000 : ~r0[5:0];
```

보드에서 비트 패턴 해석 없이 **“전부 켜짐 = PASS”** 만 보면 됨.

---

## 그 다음 (선택, 완성 후)

1. UART로 R0 출력  
2. `asm.py`로 프로그램 바꾸기  
3. Git push / README 스크린샷  
