// ============================================================================
// tb_cpu_v2.v - ISA v2 테스트 (JZ, CALL, RET, OUT)
// ============================================================================

`timescale 1ns / 1ps

module tb_cpu_v2;

    reg         clk;
    reg         reset;
    reg  [7:0]  io_in_data;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;
    wire        io_out_strobe;
    wire [7:0]  io_out_port;
    wire [7:0]  io_out_data;

    integer pass_count;
    integer fail_count;
    reg [7:0] uart_log [0:15];
    integer uart_len;

    cpu uut (
        .clk           (clk),
        .reset         (reset),
        .r0            (r0),
        .r1            (r1),
        .r2            (r2),
        .r3            (r3),
        .pc_out        (pc_out),
        .io_out_strobe (io_out_strobe),
        .io_out_port   (io_out_port),
        .io_out_data   (io_out_data),
        .io_in_data    (io_in_data)
    );

    wire        uart_busy;
    wire        uart_send = io_out_strobe && (io_out_port == 8'd0) && !uart_busy;
    wire        uart_tx;

    uart_tx u_uart (
        .clk     (clk),
        .reset   (reset),
        .data_in (io_out_data),
        .send    (uart_send),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset && io_out_strobe && io_out_port == 8'd0 && uart_len < 16) begin
            uart_log[uart_len] = io_out_data;
            uart_len = uart_len + 1;
            $display("[UART] 0x%02h '%c'", io_out_data,
                     (io_out_data >= 8'h20 && io_out_data <= 8'h7E) ? io_out_data : 8'h3F);
        end
    end

    task load_test_v2;
        integer k;
        reg [15:0] prog [0:15];
        begin
            for (k = 0; k < 256; k = k + 1)
                uut.u_ram.memory[k] = 16'h0000;
            prog[0]  = 16'h1000;
            prog[1]  = 16'h9004;
            prog[2]  = 16'h1063;
            prog[3]  = 16'h800C;
            prog[4]  = 16'h1007;
            prog[5]  = 16'h1401;
            prog[6]  = 16'h940B;
            prog[7]  = 16'hA009;
            prog[8]  = 16'h800C;
            prog[9]  = 16'h142A;
            prog[10] = 16'hB000;
            prog[11] = 16'h1400;
            prog[12] = 16'h1841;
            prog[13] = 16'hC200;
            prog[14] = 16'h800C;
            for (k = 0; k < 15; k = k + 1)
                uut.u_ram.memory[k] = prog[k];
            $display("[INFO] Loaded test_v2.asm (15 words)");
        end
    endtask

    task check_eq;
        input [255:0] name;
        input [15:0]  exp;
        input [15:0]  got;
        begin
            if (got === exp) begin
                $display("[PASS] %s: %0d", name, got);
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
        uart_len   = 0;
        io_in_data = 8'h00;
        reset      = 1;

        $display("========================================");
        $display(" HAEUN-16 ISA v2 TestBench");
        $display("========================================");

        #100;
        load_test_v2();

        #20;
        reset = 0;

        repeat (200) @(posedge clk);

        $display("----------------------------------------");
        check_eq("R0 (JZ)", 16'd7,  r0);
        check_eq("R1 (CALL/RET)", 16'd42, r1);
        check_eq("R2 (OUT src)", 16'd65, r2);
        if (uart_len >= 1 && uart_log[0] === 8'h41)
            $display("[PASS] UART byte 'A'");
        else
            $display("[FAIL] UART byte expected 0x41");

        $display("----------------------------------------");
        $display(" Result: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" *** ISA v2 TESTS PASS ***");
        else
            $display(" *** ISA v2 TESTS FAILED ***");
        $display("========================================");

        $finish;
    end

endmodule
