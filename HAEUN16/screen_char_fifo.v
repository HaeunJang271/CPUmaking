// ============================================================================
// screen_char_fifo.v - CPU(sys_clk) -> HDMI(pix_clk) 문자 FIFO (저속 안전)
// ============================================================================

module screen_char_fifo #(
    parameter DEPTH = 32,
    parameter AW    = 5
)(
    input  wire       wr_clk,
    input  wire       wr_reset,
    input  wire       wr_en,
    input  wire [14:0] wr_data,
    input  wire       rd_clk,
    input  wire       rd_reset,
    output reg        rd_valid,
    output reg  [14:0] rd_data,
    output wire       empty,
    output wire       full
);
    reg [14:0] mem [0:DEPTH-1];
    reg [AW:0] wptr;
    reg [AW:0] rptr;
    reg [AW:0] wptr_sync1;
    reg [AW:0] wptr_sync2;
    reg [AW:0] rptr_sync1;
    reg [AW:0] rptr_sync2;

    wire [AW:0] wcount = wptr - rptr_sync2;
    wire [AW:0] rcount = wptr_sync2 - rptr;

    assign full  = (wcount >= DEPTH);
    assign empty = (rcount == 0);

    always @(posedge wr_clk) begin
        if (wr_reset)
            wptr <= {AW+1{1'b0}};
        else if (wr_en && !full) begin
            mem[wptr[AW-1:0]] <= wr_data;
            wptr <= wptr + 1'b1;
        end
    end

    always @(posedge rd_clk) begin
        wptr_sync1 <= wptr;
        wptr_sync2 <= wptr_sync1;
    end

    always @(posedge wr_clk) begin
        rptr_sync1 <= rptr;
        rptr_sync2 <= rptr_sync1;
    end

    always @(posedge rd_clk) begin
        rd_valid <= 1'b0;
        if (rd_reset) begin
            rptr   <= {AW+1{1'b0}};
            rd_data <= 15'd0;
        end else if (!empty) begin
            rd_data  <= mem[rptr[AW-1:0]];
            rd_valid <= 1'b1;
            rptr     <= rptr + 1'b1;
        end
    end
endmodule
