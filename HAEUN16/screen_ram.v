// ============================================================================
// screen_ram.v - HDMI 텍스트 (쓰기=sys_clk, 읽기=pix_clk, 듀얼포트)
// ============================================================================
// 텍스트는 CPU OUT port 1 만 기록 (하드웨어 부트 문자열 없음 -> UART 와 동일)

module screen_ram (
    input  wire       wr_clk,
    input  wire       wr_reset,
    input  wire       wr_en,
    input  wire       wr_stream,
    input  wire [5:0] wr_addr,
    input  wire [7:0] wr_data,
    input  wire       cursor_load,
    input  wire [5:0] cursor_val,
    input  wire       rd_clk,
    input  wire [5:0] rd_addr,
    output reg  [7:0] rd_data,
    output wire [5:0] msg_stop
);
    reg [7:0] mem [0:63];
    reg [5:0] cursor;
    reg [5:0] msg_stop_wr;
    reg [5:0] msg_stop_rd1;
    reg [5:0] msg_stop_rd2;

    integer ri;

    always @(posedge wr_clk) begin
        if (wr_reset) begin
            cursor      <= 6'd0;
            msg_stop_wr <= 6'd0;
            for (ri = 0; ri < 64; ri = ri + 1)
                mem[ri] <= 8'd0;
        end else if (cursor_load) begin
            cursor <= cursor_val;
        end else if (wr_en) begin
            if (wr_stream) begin
                mem[cursor] <= wr_data;
                if (cursor < 6'd63)
                    cursor <= cursor + 6'd1;
                if (cursor + 6'd1 > msg_stop_wr)
                    msg_stop_wr <= cursor + 6'd1;
            end else begin
                mem[wr_addr] <= wr_data;
                if (wr_addr + 6'd1 > msg_stop_wr)
                    msg_stop_wr <= wr_addr + 6'd1;
                if (wr_addr >= cursor)
                    cursor <= wr_addr + 6'd1;
            end
        end
    end

    always @(posedge rd_clk) begin
        msg_stop_rd1 <= msg_stop_wr;
        msg_stop_rd2 <= msg_stop_rd1;
        rd_data      <= (rd_addr < msg_stop_rd2) ? mem[rd_addr] : 8'h00;
    end

    assign msg_stop = msg_stop_rd2;
endmodule
