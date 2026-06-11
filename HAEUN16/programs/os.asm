; ============================================================================
; os.asm - HAEUN-OS v0.1 (UART 셸 스켈레톤)
; ============================================================================
; 출력: "HAEUN-OS v0.1\n> " 반복
; 완료 표시: R1 = 1 (top LED 6개 ON)
; port 0 = UART TX/RX (시뮬·FPGA)
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
    LOAD R0, 79
    CALL SEND
    LOAD R0, 83
    CALL SEND
    LOAD R0, 32
    CALL SEND
    LOAD R0, 118
    CALL SEND
    LOAD R0, 48
    CALL SEND
    LOAD R0, 46
    CALL SEND
    LOAD R0, 49
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
