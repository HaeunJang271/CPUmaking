// ============================================================================
// top_uart_tx_only.v - UART TX만 검증 (RX/에코 없음, BL702 대기 없음)
// ============================================================================
// ext_uart cst로 Program 후:
//   python tools/uart_listen.py COM7
//   → UART_OK 가 반복되면 pin TX 배선 OK
// ============================================================================

module top_uart_tx_only (
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

    wire reset = ~rst_sync2;

    wire       fifo_full;
    wire       msg_wr;
    wire [7:0] msg_data;

    uart_msg_tx u_msg (
        .clk       (sys_clk),
        .reset     (reset),
        .fifo_full (fifo_full),
        .wr_en     (msg_wr),
        .wr_data   (msg_data)
    );

    uart_fifo_tx #(
        .CLK_HZ   (27_000_000),
        .BAUDRATE (115200)
    ) u_tx (
        .clk     (sys_clk),
        .reset   (reset),
        .wr_en   (msg_wr),
        .wr_data (msg_data),
        .full    (fifo_full),
        .tx      (uart_tx),
        .busy    ()
    );

    reg [23:0] hb;

    always @(posedge sys_clk) begin
        if (reset)
            hb <= 24'd0;
        else
            hb <= hb + 1'b1;
    end

    assign led = {5'b0, hb[23]};

endmodule
