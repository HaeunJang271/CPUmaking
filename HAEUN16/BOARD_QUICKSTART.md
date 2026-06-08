# Tang Nano 9K — 보드 도착 후 10분 체크리스트

비트스트림(PnR)까지 끝난 상태에서 **가장 빠르게 “완성” 확인**하는 순서입니다.

---

## 사전 준비 (보드 없을 때, 이미 했으면 SKIP)

- [x] Gowin: Synthesize + Place & Route 성공
- [x] `impl/pnr/top_tangnano9k.fs` 파일 존재
- [ ] `uart_tx.v` 추가 + `top_tangnano9k.v` / `cst` 갱신 후 **PnR** (아래 0단계)

---

## 0단계: top 갱신 후 재빌드 (2분)

`top_tangnano9k.v`를 수정했다면 Gowin에서:

1. **Synthesize** → **Place & Route**
2. 새 `.fs` 생성 확인

**PASS 표시:** LED 6개 ON + (선택) UART `HAEUN-16 Boot` 출력.

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
| LED 6개 ON | R1=1 — boot 펌웨어 완료 (UART 메시지도 확인) |
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

---

## 4단계: UART 부트 확인 (선택, pin 17)

비트스트림을 **boot + UART** 버전으로 다시 PnR 한 경우:

1. 시리얼 터미널 **115200 8N1** (Tera Term, PuTTY, `python -m serial.tools.miniterm`)
2. Tang Nano 9K **pin 17 (TX)** → USB-UART **RX** (3.3V)
3. **S1** 리셋
4. 터미널 출력:

```text
HAEUN-16 Boot
> 
```

5. **LED 6개 ON** = R1=1 (부트 완료)

Gowin 소스 추가: `uart_tx.v`  
상세: [programs/BOOT.md](programs/BOOT.md)

---

이후 확장(VGA, SD 등)은 **선택**.
