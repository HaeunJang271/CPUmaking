; ============================================================================
; boot.asm - HAEUN-16 UART 부트 펌웨어 (port 0 = UART TX, 115200)
; ============================================================================
; 출력: "HAEUN-16 Boot\n> " 반복
; 완료 표시: R1 = 1 (top LED 6개 ON)
; ============================================================================

    JMP BOOT

SEND:
    OUT R0, 0
    RET

BOOT:
    LOAD R0, 72
    CALL SEND
    LOAD R0, 65
    CALL SEND
    LOAD R0, 69
    CALL SEND
    LOAD R0, 85
    CALL SEND
    LOAD R0, 78
    CALL SEND
    LOAD R0, 45
    CALL SEND
    LOAD R0, 49
    CALL SEND
    LOAD R0, 54
    CALL SEND
    LOAD R0, 32
    CALL SEND
    LOAD R0, 66
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 116
    CALL SEND
    LOAD R0, 10
    CALL SEND
    LOAD R1, 1

PROMPT:
    LOAD R0, 62
    CALL SEND
    LOAD R0, 32
    CALL SEND
    JMP PROMPT
