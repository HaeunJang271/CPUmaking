// ============================================================================
// tb_register16.v - register16 모듈 테스트벤치
// ============================================================================
// 테스트 케이스:
//   1) reset 후 data_out = 0
//   2) load=1, data_in=123 저장
//   3) load=0, 여러 클럭 동안 123 유지
//   4) reset=1, data_out = 0
// ============================================================================

`timescale 1ns / 1ps

module tb_register16;

    // DUT 입력/출력
    reg         clk;
    reg         reset;
    reg         load;
    reg  [15:0] data_in;
    wire [15:0] data_out;

    // 테스트 통과/실패 카운터
    integer pass_count;
    integer fail_count;

    // DUT (Device Under Test) 인스턴스
    register16 uut (
        .clk      (clk),
        .reset    (reset),
        .load     (load),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // -------------------------------------------------------------------------
    // 클럭 생성: 주기 10ns (100MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // 1 클럭 사이클 대기 (상승 에지 1회)
    // -------------------------------------------------------------------------
    task clock_cycle;
        begin
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // 검증 태스크: 기대값과 비교 후 PASS/FAIL 출력
    // -------------------------------------------------------------------------
    task check_result;
        input [255:0] test_name;
        input [15:0]  exp_value;
        begin
            // nonblocking 할당 반영 후 샘플링
            #1;
            if (data_out === exp_value) begin
                $display("[PASS] %s: data_out=%0d", test_name, data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       Expected: data_out=%0d", exp_value);
                $display("       Actual:   data_out=%0d", data_out);
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

        clk      = 0;
        reset    = 0;
        load     = 0;
        data_in  = 16'd0;

        $display("========================================");
        $display(" HAEUN-16 register16 TestBench");
        $display("========================================");

        // 테스트 1: reset -> 0
        reset   = 1;
        load    = 0;
        data_in = 16'd123;
        clock_cycle();
        check_result("reset to zero", 16'd0);

        // 테스트 2: 123 저장
        reset   = 0;
        load    = 1;
        data_in = 16'd123;
        clock_cycle();
        check_result("load value 123", 16'd123);

        // 테스트 3: load=0, 값 유지 (data_in 변경해도 무시)
        load    = 0;
        data_in = 16'd999;
        clock_cycle();
        check_result("hold 123 (cycle 1)", 16'd123);
        clock_cycle();
        check_result("hold 123 (cycle 2)", 16'd123);

        // 테스트 4: reset 동작
        reset   = 1;
        load    = 1;
        data_in = 16'd123;
        clock_cycle();
        check_result("reset clears register", 16'd0);

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
