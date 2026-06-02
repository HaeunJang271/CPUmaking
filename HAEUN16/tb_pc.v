// ============================================================================
// tb_pc.v - pc 모듈 테스트벤치
// ============================================================================
// 테스트 케이스:
//   1) reset -> pc_out = 0
//   2) enable x3 -> 1, 2, 3
//   3) enable=0 -> 값 유지
//   4) jump -> jump_addr
//   5) enable -> jump_addr+1
//   6) reset -> 0
// ============================================================================

`timescale 1ns / 1ps

module tb_pc;

    // DUT 입력/출력
    reg         clk;
    reg         reset;
    reg         enable;
    reg         jump;
    reg  [15:0] jump_addr;
    wire [15:0] pc_out;

    // 테스트 통과/실패 카운터
    integer pass_count;
    integer fail_count;

    // DUT (Device Under Test) 인스턴스
    pc uut (
        .clk       (clk),
        .reset     (reset),
        .enable    (enable),
        .jump      (jump),
        .jump_addr (jump_addr),
        .pc_out    (pc_out)
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
    // 검증 태스크
    // -------------------------------------------------------------------------
    task check_result;
        input [255:0] test_name;
        input [15:0]  exp_pc;
        begin
            #1;
            if (pc_out === exp_pc) begin
                $display("[PASS] %s: pc_out=%0d (0x%04h)", test_name, pc_out, pc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       Expected: pc_out=%0d (0x%04h)", exp_pc, exp_pc);
                $display("       Actual:   pc_out=%0d (0x%04h)", pc_out, pc_out);
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

        clk       = 0;
        reset     = 0;
        enable    = 0;
        jump      = 0;
        jump_addr = 16'h0000;

        $display("========================================");
        $display(" HAEUN-16 pc TestBench");
        $display("========================================");

        // 테스트 1: reset
        reset  = 1;
        enable = 0;
        jump   = 0;
        clock_cycle();
        check_result("reset to zero", 16'd0);

        // 테스트 2: enable로 1, 2, 3 증가
        reset  = 0;
        enable = 1;
        jump   = 0;
        clock_cycle();
        check_result("increment to 1", 16'd1);
        clock_cycle();
        check_result("increment to 2", 16'd2);
        clock_cycle();
        check_result("increment to 3", 16'd3);

        // 테스트 3: enable=0 유지
        enable = 0;
        clock_cycle();
        check_result("hold at 3", 16'd3);
        clock_cycle();
        check_result("hold at 3 again", 16'd3);

        // 테스트 4: jump
        jump      = 1;
        jump_addr = 16'h0100;
        enable    = 1;   // jump가 enable보다 우선
        clock_cycle();
        check_result("jump to 0x0100", 16'h0100);
        jump = 0;

        // 테스트 5: jump 후 enable 증가
        clock_cycle();
        check_result("increment after jump", 16'h0101);

        // 테스트 6: reset
        reset  = 1;
        enable = 1;
        clock_cycle();
        check_result("reset after jump", 16'd0);

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
