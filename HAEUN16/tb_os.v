// ============================================================================
// tb_os.v - HAEUN-OS v0.1 시뮬 (부트 + help/version/echo 명령)
// ============================================================================

`timescale 1ns / 1ps

module tb_os;

    localparam integer CLK_HZ   = 1_000_000;
    localparam integer BAUDRATE = 115200;
    localparam integer BAUD_DIV = (CLK_HZ + (BAUDRATE / 2)) / BAUDRATE;

    reg        clk;
    reg        reset;
    reg        uart_rx_rst;
    reg        uart_rx_pin;
    wire [15:0] r0, r1, pc_out;
    wire        io_strobe;
    wire [7:0]  io_data;
    wire [7:0]  io_port;
    wire        io_in_strobe;
    wire [7:0]  io_in_port;
    wire [7:0]  io_in_data;

    reg [7:0] tx_log [0:511];
    integer   tx_len;
    integer   i;
    integer   b;

    cpu u_cpu (
        .clk(clk), .reset(reset),
        .r0(r0), .r1(r1), .r2(), .r3(), .pc_out(pc_out),
        .io_out_strobe(io_strobe),
        .io_out_port(io_port),
        .io_out_data(io_data),
        .io_in_strobe(io_in_strobe),
        .io_in_port(io_in_port),
        .io_in_data(io_in_data),
        .screen_wr(), .screen_addr(), .screen_data(),
        .peek_clk(clk), .peek_addr(8'd0), .peek_data()
    );

    wire uart_tx;
    wire uart_tx_full;
    wire uart_tx_busy;

    uart_fifo_tx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_uart_tx (
        .clk(clk), .reset(reset),
        .wr_en(io_strobe && (io_port == 8'd0)),
        .wr_data(io_data),
        .full(uart_tx_full),
        .tx(uart_tx),
        .busy(uart_tx_busy)
    );

    uart_fifo_rx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_uart_rx (
        .clk(clk), .reset(reset | uart_rx_rst),
        .rx(uart_rx_pin),
        .rd_en(io_in_strobe && (io_in_port == 8'd0)),
        .rd_data(io_in_data),
        .empty(),
        .full()
    );

    initial clk = 0;
    always #(500.0) clk = ~clk;

    always @(posedge clk) begin
        if (!reset && io_strobe && io_port == 8'd0 && tx_len < 512) begin
            tx_log[tx_len] = io_data;
            tx_len = tx_len + 1;
        end
    end

    task send_bit(input bit_val);
        begin
            uart_rx_pin = bit_val;
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    task send_byte(input [7:0] data);
        begin
            send_bit(1'b0);
            for (b = 0; b < 8; b = b + 1)
                send_bit(data[b]);
            send_bit(1'b1);
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    task wait_shell;
        begin
            repeat (BAUD_DIV * 800) @(posedge clk);
        end
    endtask

    task flush_rx;
        begin
            uart_rx_rst = 1'b1;
            repeat (8) @(posedge clk);
            uart_rx_rst = 1'b0;
            repeat (BAUD_DIV * 4) @(posedge clk);
        end
    endtask

    task send_cmd;
        begin
            uart_rx_pin = 1'b1;
            flush_rx;
            repeat (BAUD_DIV * 16) @(posedge clk);
        end
    endtask

    function integer find_byte;
        input integer start;
        input [7:0] ch;
        integer j;
        begin
            find_byte = -1;
            for (j = start; j < tx_len; j = j + 1)
                if (tx_log[j] === ch) begin
                    find_byte = j;
                    j = tx_len;
                end
        end
    endfunction

    function integer find_seq2;
        input integer start;
        input [7:0] a;
        input [7:0] b;
        integer j;
        begin
            find_seq2 = -1;
            for (j = start; j < tx_len - 1; j = j + 1)
                if (tx_log[j] === a && tx_log[j + 1] === b) begin
                    find_seq2 = j;
                    j = tx_len;
                end
        end
    endfunction

    reg boot_ok;
    reg help_ok;
    reg ver_ok;
    reg echo_ok;
    integer mark;
    integer pos;

    initial begin
        tx_len      = 0;
        uart_rx_pin = 1'b1;
        uart_rx_rst = 1'b0;
        reset       = 1'b1;

        repeat (16) @(posedge clk);
        reset = 1'b0;

        while (r1 !== 16'd1) @(posedge clk);
        repeat (BAUD_DIV * 200) @(posedge clk);

        boot_ok = 1'b1;
        if (tx_len < 14)
            boot_ok = 1'b0;
        else if (tx_log[0] !== 8'd72 || tx_log[5] !== 8'd45 || tx_log[12] !== 8'd49)
            boot_ok = 1'b0;

        mark = tx_len;
        send_cmd;
        send_byte("h"); send_byte("e"); send_byte("l"); send_byte("p"); send_byte(8'h0A);
        wait_shell;
        help_ok = (find_seq2(mark, 8'd114, 8'd101) >= 0);

        mark = tx_len;
        send_cmd;
        send_byte("v"); send_byte("e"); send_byte("r");
        send_byte("s"); send_byte("i"); send_byte("o"); send_byte("n");
        send_byte(8'h0A);
        wait_shell;
        ver_ok = (find_seq2(mark, 8'd118, 8'd48) >= 0);

        mark = tx_len;
        send_cmd;
        send_byte("e"); send_byte("c"); send_byte("h"); send_byte("o");
        send_byte(8'd32);
        send_byte("h"); send_byte("i");
        send_byte(8'h0A);
        wait_shell;
        echo_ok = (find_seq2(mark, 8'd104, 8'd105) >= 0);

        $display("----------------------------------------");
        $display("HAEUN-OS sim: TX %0d bytes", tx_len);

        if (boot_ok)
            $display("[PASS] boot banner");
        else
            $display("[FAIL] boot banner");

        if (help_ok)
            $display("[PASS] help command");
        else
            $display("[FAIL] help command");

        if (ver_ok)
            $display("[PASS] version command");
        else
            $display("[FAIL] version command");

        if (echo_ok)
            $display("[PASS] echo command");
        else
            $display("[FAIL] echo command");

        if (boot_ok && help_ok && ver_ok && echo_ok)
            $display("*** HAEUN-OS TEST PASS ***");
        else
            $display("*** HAEUN-OS TEST FAILED ***");
        $display("----------------------------------------");
        $finish;
    end

endmodule
