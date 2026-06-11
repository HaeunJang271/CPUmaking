// ============================================================================
// top_uart_smoke.v - BL702 UART 경로 스모크 (CPU 없음)
// ============================================================================

module top_uart_smoke (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    output wire [5:0] led,
    output wire       uart_tx
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

    wire reset = ~rst_sync2 | bl702_hold;

    wire       fifo_full;
    wire       smoke_wr;
    wire [7:0] smoke_data;
    wire       busy;

    uart_msg_tx u_msg (
        .clk       (sys_clk),
        .reset     (reset),
        .fifo_full (fifo_full),
        .wr_en     (smoke_wr),
        .wr_data   (smoke_data)
    );

    uart_path_bl702 u_uart (
        .clk     (sys_clk),
        .reset   (reset),
        .wr_en   (smoke_wr),
        .wr_data (smoke_data),
        .full    (fifo_full),
        .busy    (busy),
        .tx      (uart_tx)
    );

    reg [23:0] hb;

    always @(posedge sys_clk) begin
        if (reset)
            hb <= 24'd0;
        else
            hb <= hb + 1'b1;
    end

    assign led = {5'b11111, ~hb[23]};

endmodule
