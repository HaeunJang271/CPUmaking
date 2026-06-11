// ============================================================================
// uart_msg_tx.v - CPU 없이 ROM 메시지를 UART FIFO에 주기적으로 쓰기
// ============================================================================
// 하드웨어 스모크: pin 17 (FPGA_TX) → BL702 → PC 경로만 검증할 때 사용
// ============================================================================

module uart_msg_tx (
    input  wire       clk,
    input  wire       reset,
    input  wire       fifo_full,
    output reg        wr_en,
    output reg [7:0]  wr_data
);

    localparam [3:0] MSG_LEN = 4'd8;

    reg [3:0]  byte_idx;
    reg [23:0] wait_cnt;

    function [7:0] msg_byte;
        input [3:0] i;
        begin
            case (i)
                4'd0: msg_byte = 8'h55; // U
                4'd1: msg_byte = 8'h41; // A
                4'd2: msg_byte = 8'h52; // R
                4'd3: msg_byte = 8'h54; // T
                4'd4: msg_byte = 8'h5F; // _
                4'd5: msg_byte = 8'h4F; // O
                4'd6: msg_byte = 8'h4B; // K
                4'd7: msg_byte = 8'h0A; // \n
                default: msg_byte = 8'h0A;
            endcase
        end
    endfunction

    // 115200 @ 27MHz: ~2343 clk/byte. 여유 두고 간격 확보
    localparam [23:0] INTER_BYTE = 24'd4000;
    localparam [23:0] INTER_MSG  = 24'd2_700_000; // ~100ms

    always @(posedge clk) begin
        wr_en <= 1'b0;

        if (reset) begin
            byte_idx <= 4'd0;
            wait_cnt <= 24'd0;
        end else if (wait_cnt != 0) begin
            wait_cnt <= wait_cnt - 1'b1;
        end else if (!fifo_full) begin
            wr_en    <= 1'b1;
            wr_data  <= msg_byte(byte_idx);

            if (byte_idx == MSG_LEN - 1) begin
                byte_idx <= 4'd0;
                wait_cnt <= INTER_MSG;
            end else begin
                byte_idx <= byte_idx + 1'b1;
                wait_cnt <= INTER_BYTE;
            end
        end
    end

endmodule
