// ============================================================================
// uart_tx.v - 8N1 UART 송신 (Tang Nano 9K, 27MHz -> 115200 baud)
// ============================================================================
// send=1 펄스 시 data_in[7:0] 1바이트 전송. busy=1 동안 새 send 무시.
// 합성: Verilog-2001
// ============================================================================

module uart_tx (
    input  wire       clk,       // 27MHz
    input  wire       reset,     // 동기 리셋 (active-high)
    input  wire [7:0] data_in,
    input  wire       send,      // 1사이클 펄스
    output reg        tx,        // UART TX (idle=1)
    output reg        busy
);

    // 27_000_000 / 115_200 = 234.375 -> 234
    localparam integer BAUD_DIV = 234;

    reg [15:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shifter;
    reg        active;

    always @(posedge clk) begin
        if (reset) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            active   <= 1'b0;
            baud_cnt <= 16'd0;
            bit_idx  <= 4'd0;
            shifter  <= 10'b1111111111;
        end else begin
            if (!active) begin
                tx <= 1'b1;
                if (send && !busy) begin
                    active   <= 1'b1;
                    busy     <= 1'b1;
                    shifter  <= {1'b1, data_in, 1'b0};
                    baud_cnt <= 16'd0;
                    bit_idx  <= 4'd0;
                    tx       <= 1'b0;
                end
            end else begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 16'd0;
                    tx       <= shifter[0];
                    shifter  <= {1'b1, shifter[9:1]};
                    if (bit_idx == 4'd9) begin
                        active <= 1'b0;
                        busy   <= 1'b0;
                        tx     <= 1'b1;
                    end else
                        bit_idx <= bit_idx + 4'd1;
                end else
                    baud_cnt <= baud_cnt + 16'd1;
            end
        end
    end

endmodule
