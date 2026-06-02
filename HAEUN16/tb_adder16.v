// ============================================================================
// tb_adder16.v - adder16 모듈 테스트벤치
// ============================================================================
// 테스트 케이스:
//   1) 5 + 3 = 8,  COUT = 0
//   2) 65535 + 1 = 0, COUT = 1
// ============================================================================

`timescale 1ns / 1ps

module tb_adder16;

    // DUT 입력/출력
    reg  [15:0] A;
    reg  [15:0] B;
    wire [15:0] SUM;
    wire        COUT;

    // 테스트 통과/실패 카운터
    integer pass_count;
    integer fail_count;

    // DUT (Device Under Test) 인스턴스
    adder16 uut (
        .A    (A),
        .B    (B),
        .SUM  (SUM),
        .COUT (COUT)
    );

    // -------------------------------------------------------------------------
    // 검증 태스크: 기대값과 비교 후 PASS/FAIL 출력
    // -------------------------------------------------------------------------
    task check_result;
        input [255:0] test_name;
        input [15:0]  exp_sum;
        input         exp_cout;
        begin
            if (SUM === exp_sum && COUT === exp_cout) begin
                $display("[PASS] %s: A=%0d, B=%0d => SUM=%0d, COUT=%0b",
                         test_name, A, B, SUM, COUT);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s: A=%0d, B=%0d", test_name, A, B);
                $display("       Expected: SUM=%0d, COUT=%0b", exp_sum, exp_cout);
                $display("       Actual:   SUM=%0d, COUT=%0b", SUM, COUT);
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
        $display(" HAEUN-16 adder16 TestBench");
        $display("========================================");

        // 테스트 1: 5 + 3 = 8, 자리올림 없음
        A = 16'd5;
        B = 16'd3;
        #10;
        check_result("5 + 3", 16'd8, 1'b0);

        // 테스트 2: 65535 + 1 = 0, COUT = 1 (16비트 오버플로)
        A = 16'hFFFF;   // 65535
        B = 16'd1;
        #10;
        check_result("65535 + 1", 16'd0, 1'b1);

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
