// ============================================================================
// tb_alu.v - alu 모듈 테스트벤치
// ============================================================================
// 테스트 케이스:
//   ADD  5 + 3 = 8,  ZERO=0
//   SUB  8 - 3 = 5,  ZERO=0
//   SUB  5 - 5 = 0,  ZERO=1
//   AND  0xFF00 & 0x0F0F = 0, ZERO=1
//   OR   0x00FF | 0xFF00 = 0xFFFF, ZERO=0
//   XOR  0xAAAA ^ 0x5555 = 0xFFFF, ZERO=0
// ============================================================================

`timescale 1ns / 1ps

module tb_alu;

    // DUT 입력/출력
    reg  [15:0] A;
    reg  [15:0] B;
    reg  [2:0]  ALU_OP;
    wire [15:0] RESULT;
    wire        ZERO;

    // 테스트 통과/실패 카운터
    integer pass_count;
    integer fail_count;

    // DUT (Device Under Test) 인스턴스
    alu uut (
        .A      (A),
        .B      (B),
        .ALU_OP (ALU_OP),
        .RESULT (RESULT),
        .ZERO   (ZERO)
    );

    // -------------------------------------------------------------------------
    // 검증 태스크: 기대값과 비교 후 PASS/FAIL 출력
    // -------------------------------------------------------------------------
    task check_result;
        input [255:0] test_name;
        input [15:0]  exp_result;
        input         exp_zero;
        begin
            #1;
            if (RESULT === exp_result && ZERO === exp_zero) begin
                $display("[PASS] %s: RESULT=%0d (0x%04h), ZERO=%0b",
                         test_name, RESULT, RESULT, ZERO);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       Expected: RESULT=%0d (0x%04h), ZERO=%0b",
                         exp_result, exp_result, exp_zero);
                $display("       Actual:   RESULT=%0d (0x%04h), ZERO=%0b",
                         RESULT, RESULT, ZERO);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // 메인 테스트 시퀀스
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("========================================");
        $display(" HAEUN-16 alu TestBench");
        $display("========================================");

        // ADD: 5 + 3 = 8
        A = 16'd5;
        B = 16'd3;
        ALU_OP = 3'b000;
        #10;
        check_result("ADD 5+3", 16'd8, 1'b0);

        // SUB: 8 - 3 = 5
        A = 16'd8;
        B = 16'd3;
        ALU_OP = 3'b001;
        #10;
        check_result("SUB 8-3", 16'd5, 1'b0);

        // SUB: 5 - 5 = 0, ZERO=1
        A = 16'd5;
        B = 16'd5;
        ALU_OP = 3'b001;
        #10;
        check_result("SUB 5-5 (zero)", 16'd0, 1'b1);

        // AND: 0xFF00 & 0x0F0F = 0
        A = 16'hFF00;
        B = 16'h0F0F;
        ALU_OP = 3'b010;
        #10;
        check_result("AND FF00&0F0F", 16'h0000, 1'b1);

        // OR: 0x00FF | 0xFF00 = 0xFFFF
        A = 16'h00FF;
        B = 16'hFF00;
        ALU_OP = 3'b011;
        #10;
        check_result("OR 00FF|FF00", 16'hFFFF, 1'b0);

        // XOR: 0xAAAA ^ 0x5555 = 0xFFFF
        A = 16'hAAAA;
        B = 16'h5555;
        ALU_OP = 3'b100;
        #10;
        check_result("XOR AAAA^5555", 16'hFFFF, 1'b0);

        // 최종 요약
        #10;
        $display("----------------------------------------");
        $display(" Result: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" *** ALL TESTS PASS ***");
        else
            $display(" *** SOME TESTS FAILED ***");
        $display("========================================");

        $finish;
    end

endmodule
