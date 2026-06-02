// ============================================================================
// tb_cpu.v - HAEUN-16 CPU 통합 테스트벤치
// ============================================================================
// 프로그램 (RAM 0~2):
//   LOAD R0, 5
//   LOAD R1, 3
//   ADD  R0, R1
// 기대 결과: R0 = 8, R1 = 3
// ============================================================================

`timescale 1ns / 1ps

module tb_cpu;

    reg         clk;
    reg         reset;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;

    integer pass_count;
    integer fail_count;
    integer cycle_count;

    cpu uut (
        .clk    (clk),
        .reset  (reset),
        .r0     (r0),
        .r1     (r1),
        .r2     (r2),
        .r3     (r3),
        .pc_out (pc_out)
    );

    // -------------------------------------------------------------------------
    // 클럭: 10ns 주기
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // RAM에 테스트 프로그램 로드 (ISA.md 기계어)
    // -------------------------------------------------------------------------
    task load_program;
        begin
            uut.u_ram.memory[0] = 16'h1005;   // LOAD R0, 5
            uut.u_ram.memory[1] = 16'h1403;   // LOAD R1, 3
            uut.u_ram.memory[2] = 16'h3100;   // ADD  R0, R1
            $display("[INFO] Program loaded into RAM:");
            $display("       [0] 0x1005  LOAD R0, 5");
            $display("       [1] 0x1403  LOAD R1, 3");
            $display("       [2] 0x3100  ADD  R0, R1");
        end
    endtask

    // -------------------------------------------------------------------------
    // 실행 로그 (매 클럭)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            $display("[CYCLE %0d] PC=%0d  R0=%0d  R1=%0d  R2=%0d  R3=%0d",
                     cycle_count, pc_out, r0, r1, r2, r3);
        end
    end

    // -------------------------------------------------------------------------
    // 검증
    // -------------------------------------------------------------------------
    task check_final;
        begin
            $display("----------------------------------------");
            $display("[CHECK] Final register values:");
            $display("        R0=%0d (expected 8)", r0);
            $display("        R1=%0d (expected 3)", r1);

            if (r0 === 16'd8) begin
                $display("[PASS] R0 == 8");
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] R0 != 8 (got %0d)", r0);
                fail_count = fail_count + 1;
            end

            if (r1 === 16'd3) begin
                $display("[PASS] R1 == 3");
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] R1 != 3 (got %0d)", r1);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // 메인 시퀀스
    // -------------------------------------------------------------------------
    initial begin
        pass_count  = 0;
        fail_count  = 0;
        cycle_count = 0;
        reset       = 1;

        $display("========================================");
        $display(" HAEUN-16 CPU Integration TestBench");
        $display("========================================");

        // RAM initial 블록 완료 대기
        #100;
        load_program();

        // CPU 리셋 해제 후 프로그램 실행 (3명령 x 3사이클/명령 + 여유)
        #20;
        $display("[INFO] CPU reset released, execution starts.");
        reset = 0;

        repeat (40) @(posedge clk);

        check_final();

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
