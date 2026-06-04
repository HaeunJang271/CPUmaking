; ============================================================================
; test_all.asm - HAEUN-16 전 opcode 통합 테스트
; ============================================================================
; 검증 항목:
;   NOP, LOAD, ADD, SUB, AND, OR, XOR, STORE, JMP
;
; 종료 시 기대값:
;   R0 = 99   (JMP target)
;   (SUB: R0=10 after ADD 13 then SUB; see TEST_ALL.md)
;   R1 = 1    (테스트 완료 마커)
;   R2 = 255  (0xAA XOR 0x55)
;   R3 = 85   (0x55)
;   RAM[32] = 3  (STORE R1)
; ============================================================================

; --- NOP ---
NOP

; --- LOAD / ADD / SUB ---
LOAD R0, 10
LOAD R1, 3
ADD R0, R1          ; R0 = 13
SUB R0, R1          ; R0 = 10

; --- AND ---
LOAD R2, 170        ; 0xAA
LOAD R3, 85         ; 0x55
AND R2, R3          ; R2 = 0

; --- OR ---
LOAD R2, 15         ; 0x0F
LOAD R3, 240        ; 0xF0
OR R2, R3           ; R2 = 255

; --- XOR ---
LOAD R2, 170
LOAD R3, 85
XOR R2, R3          ; R2 = 255

; --- STORE (R1 still 3 from load at addr 2) ---
STORE R1, 32

; --- JMP (skip dead code) ---
JMP 18
LOAD R0, 0          ; dead
NOP                 ; dead

; --- address 18: JMP target ---
LOAD R0, 99
LOAD R1, 1          ; all tests done
