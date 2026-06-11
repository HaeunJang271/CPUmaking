// ============================================================================
// uart_path_bl702.v - Tang Nano 9K 온보드 BL702 UART 경로 (FPGA pin 17)
// ============================================================================
// 회로: FPGA_TX(pin17) -> BL702 UART_RX -> USB CDC (COM, 번호 큰 쪽)
// 제약: tangnano9k.cst 의 uart_tx = pin 17
// ============================================================================

module uart_path_bl702 #(
    parameter integer CLK_HZ   = 27_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       wr_en,
    input  wire [7:0] wr_data,
    output wire       full,
    output wire       busy,
    output wire       tx
);

    uart_fifo_tx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_fifo (
        .clk     (clk),
        .reset   (reset),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),
        .tx      (tx),
        .busy    (busy)
    );

endmodule
