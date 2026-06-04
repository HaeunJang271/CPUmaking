# Tang Nano 9K — 보드 도착 후 10분 체크리스트

비트스트림(PnR)까지 끝난 상태에서 **가장 빠르게 “완성” 확인**하는 순서입니다.

---

## 사전 준비 (보드 없을 때, 이미 했으면 SKIP)

- [x] Gowin: Synthesize + Place & Route 성공
- [x] `impl/pnr/top_tangnano9k.fs` 파일 존재
- [ ] `top_tangnano9k.v` **done LED** 버전으로 **한 번 더 PnR** (아래 0단계)

---

## 0단계: top 갱신 후 재빌드 (2분)

`top_tangnano9k.v`를 수정했다면 Gowin에서:

1. **Synthesize** → **Place & Route**
2. 새 `.fs` 생성 확인

**PASS 표시:** 보드에서 **LED 6개가 모두 켜지면** 성공 (active-low).

---

## 1단계: 연결 (1분)

1. Tang Nano 9K USB-C → PC
2. Gowin **Program Device** 실행

---

## 2단계: 다운로드 (2분)

1. **Open** → `HAEUN16_9K\impl\pnr\top_tangnano9k.fs`
2. Device: **GW1NR-9** 인식 확인
3. **Program / Download**
4. Success 확인

Programmer 실패 시: Sipeed Wiki → Tang Programmer 교체.

---

## 3단계: 동작 확인 (1분)

1. **S1 버튼**(pin 4) **눌렀다 떼기** (리셋)
2. **1초 이내** → **LED 6개 전부 ON** 이면 **프로젝트 완료**

| 결과 | 의미 |
|------|------|
| LED 6개 ON | R0=8, R1=3 — CPU + 프로그램 OK |
| LED 일부만 / 안 켜짐 | 리셋 다시 / 재다운로드 / PnR 재실행 |

---

## 실패 시 30초 점검

| 확인 | |
|------|--|
| Part | GW1NR-LV9QN88PC6/I5 |
| Top | top_tangnano9k |
| 소스 | ram_fpga.v (ram.v 아님) |
| cst | tangnano9k.cst 포함 |

---

## 완성 정의

```text
[소프트웨어] 시뮬 PASS + Gowin PnR OK     <- 지금 여기
[하드웨어]  LED 6개 ON after reset      <- 보드 10분
```

이후 확장(UART, VGA 등)은 **선택**.
