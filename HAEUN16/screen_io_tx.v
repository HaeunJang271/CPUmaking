// ============================================================================
// screen_io_tx.v - OUT port 1 스트림 (screen_bridge 로 전달)
// ============================================================================

module screen_io_tx (
    input  wire       clk,
    input  wire       reset,
    input  wire       wr_en,
    input  wire [7:0] wr_data,
    output wire       stream_wr,
    output wire [7:0] stream_data
);
    assign stream_wr   = wr_en && (wr_data != 8'd13);
    assign stream_data = wr_data;
endmodule
