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

1. `sync_gowin.ps1` → `uart_tx.v` + **`uart_fifo_tx.v`** 포함
2. **Syn + PnR** → Program `HAEUN16_9K.fs`
3. 온보드 USB-UART COM 포트, **115200 8N1**
4. 리셋 후 `HAEUN-16 Boot` / `> `

상세: [UART_TX.md](../UART_TX.md)
