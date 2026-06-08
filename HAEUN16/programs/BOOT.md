# boot.asm — UART 부트 펌웨어

## 출력

```
HAEUN-16 Boot
> 
```

`>` 프롬프트는 무한 반복. **R1=1** 이면 부트 완료 (top LED 6개 ON).

## 빌드

```powershell
python tools\asm.py programs\boot.asm
python tools\asm.py programs\boot.asm --verilog   # ram_fpga initial 스니펫
```

`ram_fpga.v` initial 블록은 이미 `boot.asm` 기준으로 갱신됨.

## 시뮬 (UART 없이 LED/R1만)

`ram_fpga`에 boot 로드 후 `tb_cpu` 대신 수동 검증 — UART는 `tb_cpu_v2` + `uart_tx.v` 참고.

## FPGA

1. Gowin 프로젝트에 `uart_tx.v` 추가
2. `top_tangnano9k.v`, `tangnano9k.cst` (pin 17) 갱신 후 **Syn + PnR**
3. pin 17 → USB-UART RX (115200 8N1)
4. 리셋 후 시리얼 터미널에서 부트 메시지 확인
