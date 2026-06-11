// ============================================================================
// screen_bridge.v - CPU / RAM미러 -> screen_ram -> HDMI
// ============================================================================

module screen_bridge (
    input  wire       sys_clk,
    input  wire       sys_reset,
    input  wire       stream_wr,
    input  wire [7:0] stream_data,
    input  wire       direct_wr,
    input  wire [5:0] direct_addr,
    input  wire [7:0] direct_data,
    input  wire       mirror_wr,
    input  wire [5:0] mirror_addr,
    input  wire [7:0] mirror_data,
    input  wire       mirror_busy,
    input  wire       cursor_load,
    input  wire [5:0] cursor_val,
    input  wire       pix_clk,
    input  wire       pix_reset,
    input  wire [5:0] rd_addr,
    output wire [7:0] rd_data,
    output wire [5:0] msg_stop
);
    wire wr_en;
    wire wr_stream;
    wire [5:0] wr_addr;
    wire [7:0] wr_data;

    wire stream_gate = stream_wr && !mirror_busy;

    assign wr_en = stream_gate | direct_wr | mirror_wr;
    assign wr_stream = stream_gate && !direct_wr && !mirror_wr;
    assign wr_addr = mirror_wr ? mirror_addr : direct_addr;
    assign wr_data = mirror_wr ? mirror_data :
                     direct_wr  ? direct_data : stream_data;

    screen_ram u_ram (
        .wr_clk      (sys_clk),
        .wr_reset    (sys_reset),
        .wr_en       (wr_en),
        .wr_stream   (wr_stream),
        .wr_addr     (wr_addr),
        .wr_data     (wr_data),
        .cursor_load (cursor_load),
        .cursor_val  (cursor_val),
        .rd_clk      (pix_clk),
        .rd_addr     (rd_addr),
        .rd_data     (rd_data),
        .msg_stop    (msg_stop)
    );
endmodule
