// ============================================================================
// tb_os_echo.v - echo 명령 단독 검증
// ============================================================================

`timescale 1ns / 1ps

module tb_os_echo;

    localparam integer CLK_HZ   = 1_000_000;
    localparam integer BAUDRATE = 115200;
    localparam integer BAUD_DIV = (CLK_HZ + (BAUDRATE / 2)) / BAUDRATE;

    reg        clk, reset, uart_rx_rst, uart_rx_pin;
    wire [15:0] r1;
    wire        io_strobe;
    wire [7:0]  io_data, io_port;
    wire        io_in_strobe;
    wire [7:0]  io_in_port;
    wire [7:0]  io_in_data;
    reg [7:0] tx_log [0:127];
    integer tx_len, i, b, mark;

    cpu u_cpu (
        .clk(clk), .reset(reset),
        .r0(), .r1(r1), .r2(), .r3(), .pc_out(),
        .io_out_strobe(io_strobe),
        .io_out_port(io_port),
        .io_out_data(io_data),
        .io_in_strobe(io_in_strobe),
        .io_in_port(io_in_port),
        .io_in_data(io_in_data),
        .screen_wr(), .screen_addr(), .screen_data(),
        .peek_clk(clk), .peek_addr(8'd0), .peek_data()
    );

    uart_fifo_rx #(.CLK_HZ(CLK_HZ), .BAUDRATE(BAUDRATE)) u_rx (
        .clk(clk), .reset(reset | uart_rx_rst),
        .rx(uart_rx_pin), .rd_en(io_in_strobe && (io_in_port == 8'd0)),
        .rd_data(io_in_data), .empty(), .full()
    );

    uart_fifo_tx #(.CLK_HZ(CLK_HZ), .BAUDRATE(BAUDRATE)) u_tx (
        .clk(clk), .reset(reset),
        .wr_en(io_strobe && (io_port == 8'd0)),
        .wr_data(io_data), .full(), .tx(), .busy()
    );

    initial clk = 0;
    always #(500.0) clk = ~clk;

    always @(posedge clk) begin
        if (!reset && io_strobe && io_port == 8'd0 && tx_len < 128)
            tx_log[tx_len++] = io_data;
    end

    task send_bit(input bit_val);
        begin uart_rx_pin = bit_val; repeat (BAUD_DIV) @(posedge clk); end
    endtask

    task send_byte(input [7:0] data);
        integer k;
        begin
            send_bit(0);
            for (k = 0; k < 8; k = k + 1) send_bit(data[k]);
            send_bit(1);
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    initial begin
        tx_len = 0; uart_rx_pin = 1; uart_rx_rst = 0; reset = 1;
        repeat (16) @(posedge clk);
        reset = 0;
        while (r1 !== 16'd1) @(posedge clk);
        repeat (BAUD_DIV * 200) @(posedge clk);

        mark = tx_len;
        send_byte("e"); send_byte("c"); send_byte("h"); send_byte("o");
        send_byte(8'd32); send_byte("h"); send_byte("i"); send_byte(8'h0A);
        repeat (BAUD_DIV * 800) @(posedge clk);

        $write("TX: ");
        for (i = mark; i < tx_len; i = i + 1) $write("%c", tx_log[i]);
        $write("\n");

        if (tx_log[mark] === 8'd32 && tx_log[mark + 1] === 8'd104 &&
            tx_log[mark + 2] === 8'd105)
            $display("*** ECHO TEST PASS ***");
        else if (tx_log[mark] === 8'd63)
            $display("*** ECHO UNKNOWN (CHK fail) ***");
        else
            $display("*** ECHO TEST FAILED ***");
        $finish;
    end
endmodule
