// ============================================================================
// tb_uart_rx.v - uart_rx 단위 테스트 (send_byte 태스크)
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_rx;

    // 시뮬 속도: 1MHz 클럭 + 115200 baud (FPGA는 27MHz 동일 baud)
    localparam integer CLK_HZ   = 1_000_000;
    localparam integer BAUDRATE = 115200;
    localparam integer BAUD_DIV = (CLK_HZ + (BAUDRATE / 2)) / BAUDRATE;

    reg        clk;
    reg        reset;
    reg        uart_line;
    wire [7:0] rx_data;
    wire       rx_valid;

    reg [7:0] captured [0:7];
    integer   cap_len;
    integer   k;
    integer   b;

    uart_rx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_rx (
        .clk      (clk),
        .reset    (reset),
        .rx       (uart_line),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    initial clk = 0;
    always #(500.0) clk = ~clk;

    always @(posedge clk) begin
        if (!reset && rx_valid && cap_len < 8) begin
            captured[cap_len] = rx_data;
            cap_len = cap_len + 1;
            $display("[RX] 0x%02h '%c'", rx_data,
                     (rx_data >= 8'h20 && rx_data <= 8'h7E) ? rx_data : 8'h3F);
        end
    end

    task send_bit(input bit_val);
        begin
            uart_line = bit_val;
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    task send_byte(input [7:0] data);
        begin
            send_bit(1'b0);
            for (b = 0; b < 8; b = b + 1)
                send_bit(data[b]);
            send_bit(1'b1);
        end
    endtask

    reg [7:0] expect [0:4];
    reg       pass;

    initial begin
        cap_len   = 0;
        uart_line = 1'b1;
        reset     = 1'b1;

        expect[0] = 8'h68;
        expect[1] = 8'h65;
        expect[2] = 8'h6C;
        expect[3] = 8'h70;
        expect[4] = 8'h0A;

        repeat (8) @(posedge clk);
        reset = 1'b0;
        repeat (8) @(posedge clk);

        send_byte("h");
        send_byte("e");
        send_byte("l");
        send_byte("p");
        send_byte(8'h0A);

        repeat (BAUD_DIV * 4) @(posedge clk);

        pass = 1'b1;
        if (cap_len != 5)
            pass = 1'b0;

        for (k = 0; k < 5; k = k + 1)
            if (captured[k] !== expect[k])
                pass = 1'b0;

        $display("----------------------------------------");
        $display("Captured %0d bytes (expect 5)", cap_len);

        if (pass)
            $display("*** UART RX TEST PASS ***");
        else
            $display("*** UART RX TEST FAILED ***");
        $display("----------------------------------------");
        $finish;
    end

endmodule
