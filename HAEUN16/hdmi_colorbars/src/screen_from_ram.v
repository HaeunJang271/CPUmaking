// ============================================================================
// screen_from_ram.v - CPU RAM 문자열 -> screen_ram 고정 슬롯 미러
// ============================================================================
// STORE_READY 완료 후(boot_done) 1회만 미러 — 부팅 전 peek 시 프로그램 코드 노출 방지

module screen_from_ram #(
    parameter [7:0] RAM_BASE   = 8'd247,
    parameter [5:0] SCREEN_POS = 6'd14,
    parameter [5:0] MAX_LEN    = 6'd5
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       boot_done,
    input  wire [15:0] ram_peek_data,
    output reg  [7:0] ram_peek_addr,
    output reg        mirror_wr,
    output reg  [5:0] mirror_addr,
    output reg  [7:0] mirror_data,
    output wire       busy
);
    reg        boot_done_d;
    reg        mirrored;
    reg        refresh_req;

    reg [2:0] state;
    reg [5:0] idx;
    reg [7:0] peek_addr_r;
    reg [7:0] char_r;

    localparam S_IDLE  = 2'd0;
    localparam S_ADDR  = 2'd1;
    localparam S_WAIT  = 2'd2;
    localparam S_WRITE = 2'd3;

    assign busy = (state != S_IDLE);

    always @(posedge clk) begin
        mirror_wr <= 1'b0;

        if (reset) begin
            boot_done_d   <= 1'b0;
            mirrored      <= 1'b0;
            refresh_req   <= 1'b0;
            state         <= S_IDLE;
            idx           <= 6'd0;
            ram_peek_addr <= RAM_BASE;
        end else begin
            boot_done_d <= boot_done;

            if (state == S_IDLE) begin
                if (!mirrored && boot_done && !boot_done_d)
                    refresh_req <= 1'b1;

                if (refresh_req) begin
                    refresh_req   <= 1'b0;
                    idx           <= 6'd0;
                    peek_addr_r   <= RAM_BASE;
                    ram_peek_addr <= RAM_BASE;
                    state         <= S_ADDR;
                end
            end else if (state == S_ADDR) begin
                state <= S_WAIT;
            end else if (state == S_WAIT) begin
                char_r <= ram_peek_data[7:0];
                state  <= S_WRITE;
            end else if (state == S_WRITE) begin
                if (char_r == 8'd0 || idx >= MAX_LEN) begin
                    mirrored <= 1'b1;
                    state    <= S_IDLE;
                end else begin
                    mirror_wr     <= 1'b1;
                    mirror_addr   <= SCREEN_POS + idx;
                    mirror_data   <= char_r;
                    idx           <= idx + 6'd1;
                    peek_addr_r   <= peek_addr_r + 8'd1;
                    ram_peek_addr <= peek_addr_r + 8'd1;
                    state         <= S_ADDR;
                end
            end
        end
    end
endmodule
