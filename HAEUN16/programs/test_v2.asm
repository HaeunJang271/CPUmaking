; ============================================================================
; test_v2.asm - ISA v2 테스트 (JZ, CALL, RET, OUT)
; ============================================================================
; 기대:
;   R0 = 7   (JZ_OK 경로)
;   R1 = 42  (CALL/RET)
;   R2 = 65  (OUT)
;   UART: "A" (0x41)
; ============================================================================

    LOAD R0, 0
    JZ R0, JZ_OK
    LOAD R0, 99
    JMP DONE

JZ_OK:
    LOAD R0, 7
    LOAD R1, 1
    JZ R1, FAIL
    CALL FUNC
    JMP DONE

FUNC:
    LOAD R1, 42
    RET

FAIL:
    LOAD R1, 0

DONE:
    LOAD R2, 65
    OUT R2, 0
    JMP DONE
