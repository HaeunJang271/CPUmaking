; ============================================================================
; os.asm - HAEUN-OS v0.1 (UART + HDMI 셸)
; ============================================================================
; 명령: help | echo <text> | version | reboot
; port 0 = UART, port 1 = HDMI stream, port 2 = HDMI cursor, RAM 247+ = 화면 문자열
; ============================================================================

    JMP BOOT

; --- I/O primitives ---------------------------------------------------------
SEND:
    OUT R0, 0
    OUT R0, 1
    RET

RECV:
    IN R0, 0
    JZ R0, RECV
    RET

SEND_CR:
    LOAD R0, 10
    CALL SEND
    RET

PRINT_PROMPT:
    LOAD R0, 62
    CALL SEND
    LOAD R0, 32
    CALL SEND
    RET

; RAM[247..] = "READY\0" -> HDMI 미러 (빈 줄은 스트림으로)
STORE_READY:
    LOAD R0, 82
    STORE R0, 247
    LOAD R0, 69
    STORE R0, 248
    LOAD R0, 65
    STORE R0, 249
    LOAD R0, 68
    STORE R0, 250
    LOAD R0, 89
    STORE R0, 251
    LOAD R0, 0
    STORE R0, 252
    RET

WAIT_MIRROR:
    LOAD R0, 0
WM_L:
    LOAD R2, 1
    ADD R0, R2
    LOAD R2, 0
    ADD R2, R0
    LOAD R3, 500
    SUB R2, R3
    JZ R2, WM_D
    JMP WM_L
WM_D:
    RET

; --- boot -------------------------------------------------------------------
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
    CALL SEND_CR
    CALL STORE_READY
    LOAD R1, 1
    CALL WAIT_MIRROR
    LOAD R0, 19
    OUT R0, 2
    CALL SEND_CR
    CALL SEND_CR
    LOAD R0, 21
    OUT R0, 2

; --- shell loop -------------------------------------------------------------
SHELL:
    CALL PRINT_PROMPT
    CALL RECV
    LOAD R1, 0
    ADD R1, R0
    LOAD R2, 104
    LOAD R0, 0
    ADD R0, R1
    SUB R0, R2
    JZ R0, CHK_HELP
    LOAD R0, 0
    ADD R0, R1
    LOAD R2, 118
    SUB R0, R2
    JZ R0, CHK_VER
    LOAD R0, 0
    ADD R0, R1
    LOAD R2, 101
    SUB R0, R2
    JZ R0, CHK_ECHO
    LOAD R0, 0
    ADD R0, R1
    LOAD R2, 114
    SUB R0, R2
    JZ R0, CHK_REBOOT
    JMP UNKNOWN

; --- help -------------------------------------------------------------------
CHK_HELP:
    CALL RECV
    LOAD R2, 101
    SUB R0, R2
    JZ R0, CHK_HELP_L
    JMP UNKNOWN
CHK_HELP_L:
    CALL RECV
    LOAD R2, 108
    SUB R0, R2
    JZ R0, CHK_HELP_P
    JMP UNKNOWN
CHK_HELP_P:
    CALL RECV
    LOAD R2, 112
    SUB R0, R2
    JZ R0, CHK_HELP_NL
    JMP UNKNOWN
CHK_HELP_NL:
    CALL RECV
    LOAD R2, 10
    SUB R0, R2
    JZ R0, DO_HELP
    JMP UNKNOWN

DO_HELP:
    LOAD R0, 104
    CALL SEND
    LOAD R0, 101
    CALL SEND
    LOAD R0, 108
    CALL SEND
    LOAD R0, 112
    CALL SEND
    LOAD R0, 32
    CALL SEND
    LOAD R0, 101
    CALL SEND
    LOAD R0, 99
    CALL SEND
    LOAD R0, 104
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 32
    CALL SEND
    LOAD R0, 118
    CALL SEND
    LOAD R0, 101
    CALL SEND
    LOAD R0, 114
    CALL SEND
    LOAD R0, 115
    CALL SEND
    LOAD R0, 105
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 110
    CALL SEND
    LOAD R0, 32
    CALL SEND
    LOAD R0, 114
    CALL SEND
    LOAD R0, 101
    CALL SEND
    LOAD R0, 98
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 111
    CALL SEND
    LOAD R0, 116
    CALL SEND
    CALL SEND_CR
    JMP SHELL

; --- version ----------------------------------------------------------------
CHK_VER:
    CALL RECV
    LOAD R2, 101
    SUB R0, R2
    JZ R0, CHK_VER_R
    JMP UNKNOWN
CHK_VER_R:
    CALL RECV
    LOAD R2, 114
    SUB R0, R2
    JZ R0, CHK_VER_S
    JMP UNKNOWN
CHK_VER_S:
    CALL RECV
    LOAD R2, 115
    SUB R0, R2
    JZ R0, CHK_VER_I
    JMP UNKNOWN
CHK_VER_I:
    CALL RECV
    LOAD R2, 105
    SUB R0, R2
    JZ R0, CHK_VER_O
    JMP UNKNOWN
CHK_VER_O:
    CALL RECV
    LOAD R2, 111
    SUB R0, R2
    JZ R0, CHK_VER_N
    JMP UNKNOWN
CHK_VER_N:
    CALL RECV
    LOAD R2, 110
    SUB R0, R2
    JZ R0, CHK_VER_NL
    JMP UNKNOWN
CHK_VER_NL:
    CALL RECV
    LOAD R2, 10
    SUB R0, R2
    JZ R0, DO_VERSION
    JMP UNKNOWN

DO_VERSION:
    LOAD R0, 118
    CALL SEND
    LOAD R0, 48
    CALL SEND
    LOAD R0, 46
    CALL SEND
    LOAD R0, 49
    CALL SEND
    CALL SEND_CR
    JMP SHELL

; --- echo (수신 완료 후 출력 — help/version 과 동일 패턴) --------------------
CHK_ECHO:
    CALL RECV
    LOAD R2, 99
    SUB R0, R2
    JZ R0, CHK_ECHO_H
    JMP UNKNOWN
CHK_ECHO_H:
    CALL RECV
    LOAD R2, 104
    SUB R0, R2
    JZ R0, CHK_ECHO_O
    JMP UNKNOWN
CHK_ECHO_O:
    CALL RECV
    LOAD R2, 111
    SUB R0, R2
    JZ R0, DO_ECHO
    JMP UNKNOWN

DO_ECHO:
    CALL RECV
    LOAD R3, 0
    ADD R3, R0
    LOAD R2, 10
    LOAD R0, 0
    ADD R0, R3
    SUB R0, R2
    JZ R0, ECHO_DONE
    LOAD R0, 0
    ADD R0, R3
    OUT R0, 0
    OUT R0, 1
    JMP DO_ECHO
ECHO_DONE:
    CALL SEND_CR
    JMP SHELL

; --- reboot -----------------------------------------------------------------
CHK_REBOOT:
    CALL RECV
    LOAD R2, 101
    SUB R0, R2
    JZ R0, CHK_REBOOT_B
    JMP UNKNOWN
CHK_REBOOT_B:
    CALL RECV
    LOAD R2, 98
    SUB R0, R2
    JZ R0, CHK_REBOOT_O1
    JMP UNKNOWN
CHK_REBOOT_O1:
    CALL RECV
    LOAD R2, 111
    SUB R0, R2
    JZ R0, CHK_REBOOT_O2
    JMP UNKNOWN
CHK_REBOOT_O2:
    CALL RECV
    LOAD R2, 111
    SUB R0, R2
    JZ R0, CHK_REBOOT_T
    JMP UNKNOWN
CHK_REBOOT_T:
    CALL RECV
    LOAD R2, 116
    SUB R0, R2
    JZ R0, CHK_REBOOT_NL
    JMP UNKNOWN
CHK_REBOOT_NL:
    CALL RECV
    LOAD R2, 10
    SUB R0, R2
    JZ R0, BOOT
    JMP UNKNOWN

; --- unknown ----------------------------------------------------------------
UNKNOWN:
    LOAD R0, 63
    CALL SEND
    CALL SEND_CR
    JMP SHELL
