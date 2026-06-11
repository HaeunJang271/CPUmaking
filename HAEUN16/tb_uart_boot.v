// ============================================================================
// tb_uart_boot.v - boot.asm UART 검증 (FIFO push + TX busy)
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_boot;

    reg clk, reset;
    wire [15:0] r0, r1, pc_out;
    wire uart_tx;
    wire io_strobe;
    wire [7:0] io_data;
    wire [7:0] io_port;

    reg [7:0] pushed [0:31];
    integer push_len;
    integer tx_busy_fall;
    reg uart_busy_d;

    cpu u_cpu (
        .clk(clk), .reset(reset),
        .r0(r0), .r1(r1), .r2(), .r3(), .pc_out(pc_out),
        .io_out_strobe(io_strobe),
        .io_out_port(io_port),
        .io_out_data(io_data),
        .io_in_data(8'h00),
        .io_in_strobe(1'b0), .io_in_port(8'd0),
        .screen_wr(), .screen_addr(), .screen_data(),
        .peek_clk(clk), .peek_addr(8'd0), .peek_data()
    );

    wire fifo_full;
    wire uart_busy;

    uart_fifo_tx u_uart_fifo (
        .clk(clk), .reset(reset),
        .wr_en(io_strobe && (io_port == 8'd0)),
        .wr_data(io_data),
        .full(fifo_full),
        .tx(uart_tx),
        .busy(uart_busy)
    );

    initial clk = 0;
    always #18.518 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            if (io_strobe && io_port == 8'd0 && push_len < 32) begin
                pushed[push_len] = io_data;
                push_len = push_len + 1;
            end
            if (uart_busy_d && !uart_busy)
                tx_busy_fall = tx_busy_fall + 1;
            uart_busy_d <= uart_busy;
        end
    end

    integer k;
    reg [7:0] expect_bytes [0:14];
    reg       str_ok;

    initial begin
        push_len      = 0;
        tx_busy_fall  = 0;
        uart_busy_d   = 0;
        reset         = 1;
        expect_bytes[0]  = 8'd72;
        expect_bytes[1]  = 8'd65;
        expect_bytes[2]  = 8'd69;
        expect_bytes[3]  = 8'd85;
        expect_bytes[4]  = 8'd78;
        expect_bytes[5]  = 8'd45;
        expect_bytes[6]  = 8'd49;
        expect_bytes[7]  = 8'd54;
        expect_bytes[8]  = 8'd32;
        expect_bytes[9]  = 8'd66;
        expect_bytes[10] = 8'd111;
        expect_bytes[11] = 8'd111;
        expect_bytes[12] = 8'd116;
        expect_bytes[13] = 8'd10;
        expect_bytes[14] = 8'd0;

        #200;
        for (k = 0; k < 256; k = k + 1)
            u_cpu.u_ram.memory[k] = 16'h0000;
        u_cpu.u_ram.memory[0]  = 16'h8003;
        u_cpu.u_ram.memory[1]  = 16'hC000;
        u_cpu.u_ram.memory[2]  = 16'hB000;
        u_cpu.u_ram.memory[3]  = 16'h1048;
        u_cpu.u_ram.memory[4]  = 16'hA001;
        u_cpu.u_ram.memory[5]  = 16'h1041;
        u_cpu.u_ram.memory[6]  = 16'hA001;
        u_cpu.u_ram.memory[7]  = 16'h1045;
        u_cpu.u_ram.memory[8]  = 16'hA001;
        u_cpu.u_ram.memory[9]  = 16'h1055;
        u_cpu.u_ram.memory[10] = 16'hA001;
        u_cpu.u_ram.memory[11] = 16'h104E;
        u_cpu.u_ram.memory[12] = 16'hA001;
        u_cpu.u_ram.memory[13] = 16'h102D;
        u_cpu.u_ram.memory[14] = 16'hA001;
        u_cpu.u_ram.memory[15] = 16'h1031;
        u_cpu.u_ram.memory[16] = 16'hA001;
        u_cpu.u_ram.memory[17] = 16'h1036;
        u_cpu.u_ram.memory[18] = 16'hA001;
        u_cpu.u_ram.memory[19] = 16'h1020;
        u_cpu.u_ram.memory[20] = 16'hA001;
        u_cpu.u_ram.memory[21] = 16'h1042;
        u_cpu.u_ram.memory[22] = 16'hA001;
        u_cpu.u_ram.memory[23] = 16'h106F;
        u_cpu.u_ram.memory[24] = 16'hA001;
        u_cpu.u_ram.memory[25] = 16'h106F;
        u_cpu.u_ram.memory[26] = 16'hA001;
        u_cpu.u_ram.memory[27] = 16'h1074;
        u_cpu.u_ram.memory[28] = 16'hA001;
        u_cpu.u_ram.memory[29] = 16'h100A;
        u_cpu.u_ram.memory[30] = 16'hA001;
        u_cpu.u_ram.memory[31] = 16'h1401;

        #50;
        reset = 0;

        while (r1 !== 16'd1) @(posedge clk);
        repeat (2000000) @(posedge clk);

        str_ok = 1'b1;
        for (k = 0; k < 14; k = k + 1)
            if (pushed[k] !== expect_bytes[k])
                str_ok = 1'b0;

        $display("----------------------------------------");
        $display("OUT total %0d, UART TX bytes: %0d", push_len, tx_busy_fall);

        if (str_ok)
            $display("[PASS] boot string (first 14 OUT bytes)");
        else
            $display("[FAIL] boot byte mismatch");

        if (push_len >= 15)
            $display("[PASS] >= 15 OUT bytes before prompt loop");
        else
            $display("[FAIL] OUT count %0d", push_len);

        if (tx_busy_fall >= 15)
            $display("[PASS] UART transmitted >= 15 bytes");
        else
            $display("[FAIL] UART tx count %0d", tx_busy_fall);

        if (r1 === 16'd1)
            $display("[PASS] R1=1 boot done");
        else
            $display("[FAIL] R1=%0d", r1);

        if (str_ok && push_len >= 15 && tx_busy_fall >= 15 && r1 === 16'd1)
            $display("*** BOOT UART TEST PASS ***");
        else
            $display("*** BOOT UART TEST FAILED ***");
        $display("----------------------------------------");
        $finish;
    end

endmodule
