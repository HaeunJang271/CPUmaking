# HDMI 컬러바 테스트 (Tang Nano 9K)

HAEUN-16 CPU와 **별도 비트스트림**입니다. Program 한 번에 하나만 올라갑니다.

| 프로젝트 | Top | 화면/동작 |
|----------|-----|-----------|
| `HAEUN16_9K` | `top_tangnano9k` | LED 6개 ON, HAEUN-OS (UART) |
| `HAEUN16_HDMI` | `top_hdmi_colorbars` | **640×480 컬러바 + 텍스트** |

## 준비물

- Tang Nano 9K + **HDMI 케이블** + 모니터/TV
- Gowin IDE (교육판 1.9.11 등, GW1NR-9C)

## 빌드 절차

```powershell
cd HAEUN16
powershell -File tools\sync_hdmi_gowin.ps1
```

1. `powershell -File tools\sync_hdmi_gowin.ps1` (RTL + Top 설정 동기화)
2. Gowin에서 `Documents\HAEUN16_HDMI\HAEUN16_HDMI.gprj` 열기  
3. **Process → Reload All** (새 `.v` 추가 후 필수 — 안 하면 `unknown module svo_hdmi_text`)
4. Hierarchy에 `top_hdmi_colorbars`가 보이는지 확인  
   - 없으면 **Design → Set Top Module** → `top_hdmi_colorbars`
5. **Synthesize → Place & Route → Generate Bitstream**  
6. HDMI 연결 후 **Program Device**

성공 시 모니터에 **컬러 테스트 패턴** 위에 왼쪽 상단 **흰 글자**:

```text
HAEUN-16
HDMI text OK
640x480 @60
```

## 소스 구조

```
hdmi_colorbars/
  HAEUN16_HDMI.gprj
  src/
    top_hdmi_colorbars.v   # PLL + 리셋
    svo_hdmi_text.v        # tcard + svo_term 오버레이 → TMDS
    svo_term_inject.v      # 부팅 시 고정 문자열
    hdmi/svo_tcard.v       # 컬러바 패턴
    gowin_rpll/, gowin_clkdiv/
    tangnano9k_hdmi.cst    # HDMI 핀 68–75, clk 52, rst 4
```

기반: [Sipeed TangNano-9K-example](https://github.com/sipeed/TangNano-9K-example) `hdmi/` (Clifford Wolf SVO).

## HAEUN-16으로 되돌리기

`sync_gowin.ps1` 후 `HAEUN16_9K.gprj`를 Program하면 LED + CPU 비트스트림으로 복귀합니다.

## 문제 해결

| 증상 | 확인 |
|------|------|
| 검은 화면 | HDMI 케이블·모니터 입력, Program이 `HAEUN16_HDMI`인지 |
| 여전히 PicoSoC 메뉴 | 이전 데모 비트스트림 — 컬러바 `.fs` 다시 Program |
| Syn 에러 `svo_defines` | `src/hdmi/` 폴더가 Gowin `src`에 복사됐는지 `sync_hdmi_gowin.ps1` 재실행 |
| **Hierarchy / Top 모듈 비어 있음** | `svo_hdmi_bars` 합성 실패였음 → `sync_hdmi_gowin.ps1` 후 **프로젝트 닫고 다시 열기** → **Reload All** → Synthesize |
