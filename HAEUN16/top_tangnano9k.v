// ============================================================================
// top_tangnano9k.v - Tang Nano 9K (GW1NR-9) 탑 모듈
// ============================================================================
// 구조 B: 온보드 BL702 UART (TX pin17, RX pin18) + 부트 딜레이
// CPU: HAEUN-16, 115200 8N1, LED: R1=1 -> 6 LED ON
// ============================================================================

module top_tangnano9k (
    input  wire       sys_clk,     // 27MHz, pin 52
    input  wire       sys_rst_n,   // S1, pin 4
    output wire [5:0] led,
    output wire       uart_tx,     // pin 17 -> BL702
    input  wire       uart_rx      // pin 18 <- BL702
);

    reg rst_sync1;
    reg rst_sync2;

    always @(posedge sys_clk) begin
        rst_sync1 <= sys_rst_n;
        rst_sync2 <= rst_sync1;
    end

    wire bl702_hold;

    bl702_boot_delay #(
        .CLK_HZ   (27_000_000),
        .DELAY_MS (2000)
    ) u_bl702_delay (
        .clk         (sys_clk),
        .rst_n       (rst_sync2),
        .hold_active (bl702_hold)
    );

    wire sys_reset = ~rst_sync2 | bl702_hold;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;
    wire        io_out_strobe;
    wire [7:0]  io_out_port;
    wire [7:0]  io_out_data;
    wire        io_in_strobe;
    wire [7:0]  io_in_port;
    wire [7:0]  io_in_data;

    cpu u_cpu (
        .clk           (sys_clk),
        .reset         (sys_reset),
        .r0            (r0),
        .r1            (r1),
        .r2            (r2),
        .r3            (r3),
        .pc_out        (pc_out),
        .io_out_strobe (io_out_strobe),
        .io_out_port   (io_out_port),
        .io_out_data   (io_out_data),
        .io_in_strobe  (io_in_strobe),
        .io_in_port    (io_in_port),
        .io_in_data    (io_in_data),
        .screen_wr     (),
        .screen_addr   (),
        .screen_data   (),
        .peek_clk      (sys_clk),
        .peek_addr     (8'd0),
        .peek_data     ()
    );

    wire uart_tx_full;
    wire uart_tx_busy;
    wire uart_wr = io_out_strobe && (io_out_port == 8'd0);

    uart_path_bl702 u_uart_tx (
        .clk     (sys_clk),
        .reset   (sys_reset),
        .wr_en   (uart_wr),
        .wr_data (io_out_data),
        .full    (uart_tx_full),
        .busy    (uart_tx_busy),
        .tx      (uart_tx)
    );

    wire uart_rx_empty;
    wire uart_rd = io_in_strobe && (io_in_port == 8'd0);

    uart_fifo_rx u_uart_rx (
        .clk     (sys_clk),
        .reset   (sys_reset),
        .rx      (uart_rx),
        .rd_en   (uart_rd),
        .rd_data (io_in_data),
        .empty   (uart_rx_empty),
        .full    ()
    );

    wire done = (r1 == 16'd1);

    assign led = done ? 6'b000000 : ~r0[5:0];

endmodule
