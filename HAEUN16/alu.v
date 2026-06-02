// ============================================================================
// alu.v - HAEUN-16 16비트 산술/논리 연산 장치 (ALU)
// ============================================================================
// ALU_OP:
//   000 ADD   RESULT = A + B
//   001 SUB   RESULT = A - B
//   010 AND   RESULT = A & B
//   011 OR    RESULT = A | B
//   100 XOR   RESULT = A ^ B
// ZERO: RESULT가 0이면 1, 아니면 0
// 합성: Verilog-2001, FPGA 이식 가능 (조합 논리)
// ============================================================================

module alu (
    input  wire [15:0] A,        // 피연산자 A
    input  wire [15:0] B,        // 피연산자 B
    input  wire [2:0]  ALU_OP,   // 연산 선택
    output reg  [15:0] RESULT,   // 연산 결과
    output reg         ZERO      // 제로 플래그
);

    always @(*) begin
        case (ALU_OP)
            3'b000: RESULT = A + B;   // ADD
            3'b001: RESULT = A - B;   // SUB
            3'b010: RESULT = A & B;   // AND
            3'b011: RESULT = A | B;   // OR
            3'b100: RESULT = A ^ B;   // XOR
            default: RESULT = 16'h0000;
        endcase

        // 결과가 0이면 ZERO = 1
        ZERO = (RESULT == 16'h0000);
    end

endmodule
