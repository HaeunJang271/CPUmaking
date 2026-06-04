// ============================================================================
// tb_cpu_all.v - 전 opcode 테스트 (programs/test_all.asm)
// ============================================================================
// NOP, LOAD, ADD, SUB, AND, OR, XOR, STORE, JMP
// 기대: R0=99, R1=1, R2=255, R3=85, RAM[32]=3
// ============================================================================

`timescale 1ns / 1ps

module tb_cpu_all;

    reg         clk;
    reg         reset;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;

    integer pass_count;
    integer fail_count;

    cpu uut (
        .clk    (clk),
        .reset  (reset),
        .r0     (r0),
        .r1     (r1),
        .r2     (r2),
        .r3     (r3),
        .pc_out (pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // python tools/asm.py programs/test_all.asm
    task load_test_all;
        integer k;
        reg [15:0] prog [0:19];
        begin
            prog[0]  = 16'h0000;
            prog[1]  = 16'h100A;
            prog[2]  = 16'h1403;
            prog[3]  = 16'h3100;
            prog[4]  = 16'h4100;
            prog[5]  = 16'h18AA;
            prog[6]  = 16'h1C55;
            prog[7]  = 16'h5B00;
            prog[8]  = 16'h180F;
            prog[9]  = 16'h1CF0;
            prog[10] = 16'h6B00;
            prog[11] = 16'h18AA;
            prog[12] = 16'h1C55;
            prog[13] = 16'h7B00;
            prog[14] = 16'h2120;
            prog[15] = 16'h8012;
            prog[16] = 16'h1000;
            prog[17] = 16'h0000;
            prog[18] = 16'h1063;
            prog[19] = 16'h1401;
            for (k = 0; k < 20; k = k + 1)
                uut.u_ram.memory[k] = prog[k];
            $display("[INFO] Loaded test_all.asm (20 words)");
        end
    endtask

    task check_eq;
        input [255:0] name;
        input [15:0]  exp;
        input [15:0]  got;
        begin
            if (got === exp) begin
                $display("[PASS] %s: %0d (0x%04h)", name, got, got);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s: expected %0d, got %0d", name, exp, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1;

        $display("========================================");
        $display(" HAEUN-16 CPU All-Opcode TestBench");
        $display("========================================");

        #100;
        load_test_all();

        #20;
        $display("[INFO] Reset release, running test_all...");
        reset = 0;

        repeat (130) @(posedge clk);

        $display("----------------------------------------");
        $display("[CHECK] Final state (all opcodes):");
        check_eq("R0 (JMP+LOAD)", 16'd99,  r0);
        check_eq("R1 (done flag)", 16'd1,  r1);
        check_eq("R2 (XOR 0xFF)", 16'd255, r2);
        check_eq("R3",           16'd85,  r3);
        check_eq("RAM[32] (STORE R1)", 16'd3, uut.u_ram.memory[32]);

        $display("----------------------------------------");
        $display(" Result: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" *** ALL OPCODE TESTS PASS ***");
        else
            $display(" *** SOME OPCODE TESTS FAILED ***");
        $display("========================================");

        $finish;
    end

endmodule
