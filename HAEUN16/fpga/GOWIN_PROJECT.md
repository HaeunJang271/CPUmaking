# Gowin EDA 프로젝트 설정 (Tang Nano 9K)

4단계 `top_tangnano9k.v` + `tangnano9k.cst` 를 보드에 올리는 방법입니다.

---

## 1. 새 프로젝트

| 항목 | 값 |
|------|-----|
| Device | **GW1NR-9** |
| Package | **QN88** (Tang Nano 9K) |
| Part (예) | GW1NR-LV9QN88PC6/I5 또는 Education 목록의 **GW1NR-9C** |
| Top module | `top_tangnano9k` |

---

## 2. Design 파일 추가

**포함:**

```
top_tangnano9k.v
cpu.v
alu.v
pc.v
register16.v
ram_fpga.v
tangnano9k.cst
tangnano9k.sdc    ; 27MHz 클럭 (TA1132 경고 제거)
```

**포함하지 않음:**

```
tb_*.v
ram.v          (64KW 시뮬 전용)
adder16.v      (cpu 내부에서 미사용)
```

---

## 3. 설정 체크

- **Project → Configuration → Place&Route → Dual-Purpose Pin**  
  → **Use DONE as regular IO** 체크

### WARN TA1132 (`sys_clk` was determined to be a clock but was not created)

- **원인:** `sys_clk` 핀은 `.cst`에만 있고, **타이밍 클럭 정의(.sdc)** 가 없음  
- **해결:** `tangnano9k.sdc` 를 프로젝트에 추가 후 **Synthesize → Place & Route** 다시 실행  
- **치명적 오류 아님** — 비트스트림은 나올 수 있으나, 클럭 제약 넣는 것이 좋음

---

## 4. 빌드 순서

1. **Synthesize**
2. **Place & Route**
3. **Generate Bitstream**
4. **Program Device** (USB, onboard JTAG)

---

## 5. 보드에서 확인

1. USB 연결 후 비트스트림 다운로드  
2. **S1 버튼**을 눌렀다 떼면 CPU 리셋 후 프로그램 재실행  
3. 잠시 후 LED 패턴 확인  

**기대 (r0=8, active-low LED):**

- `r0[5:0] = 6'b001000`  
- `led = ~r0[5:0] = 6'b110111` (보드에 따라 밝기/패턴으로 “8” 완료 여부 확인)

---

## 6. RAM 초기화

- `ram_fpga.v` 의 `initial` 블록 사용  
- 또는 BRAM IP + `program.mi` (상위 폴더)

---

## 7. 문제 해결

| 증상 | 확인 |
|------|------|
| Programmer 인식 안 됨 | Sipeed Wiki Programmer 교체 안내 |
| 합성 실패 (메모리) | `ram_fpga.v` 사용 여부, `ram.v` 제외 |
| LED 안 변함 | 리셋 버튼 눌렀다 떼기, `led` active-low 이해 |

---

## 8. Education Edition

Tang Nano 9K (**GW1NR-9C**) 는 Education IDE 에서 합성 가능 (라이선스 불필요).
