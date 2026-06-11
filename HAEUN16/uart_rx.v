// ============================================================================
// uart_rx.v - 8N1 UART 수신 (Tang Nano 9K, 27MHz -> 115200 baud)
// ============================================================================
// start bit 검출 -> 8비트 LSB-first -> stop bit 확인 -> rx_valid 1사이클 펄스
// 합성: Verilog-2001
// ============================================================================

module uart_rx #(
    parameter integer CLK_HZ   = 27_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       reset,     // 동기 리셋 (active-high)
    input  wire       rx,        // UART RX (idle=1)
    output reg  [7:0] rx_data,
    output reg        rx_valid   // 수신 완료 1사이클 펄스
);

    localparam integer BAUD_DIV  = (CLK_HZ + (BAUDRATE / 2)) / BAUDRATE;
    localparam integer HALF_BAUD = BAUD_DIV / 2;

    reg [15:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [7:0]  data_reg;
    reg        active;

    wire [15:0] baud_target = (bit_idx == 4'd0) ? HALF_BAUD : BAUD_DIV;

    always @(posedge clk) begin
        rx_valid <= 1'b0;

        if (reset) begin
            active   <= 1'b0;
            baud_cnt <= 16'd0;
            bit_idx  <= 4'd0;
            data_reg <= 8'h00;
            rx_data  <= 8'h00;
        end else if (!active) begin
            baud_cnt <= 16'd0;
            if (rx == 1'b0) begin
                active   <= 1'b1;
                bit_idx  <= 4'd0;
                baud_cnt <= 16'd0;
            end
        end else begin
            if (baud_cnt == baud_target - 1) begin
                baud_cnt <= 16'd0;

                if (bit_idx == 4'd0) begin
                    if (rx == 1'b0)
                        bit_idx <= 4'd1;
                    else
                        active <= 1'b0;
                end else if (bit_idx <= 4'd8) begin
                    data_reg[bit_idx - 4'd1] <= rx;
                    if (bit_idx == 4'd8)
                        bit_idx <= 4'd9;
                    else
                        bit_idx <= bit_idx + 4'd1;
                end else begin
                    if (rx == 1'b1) begin
                        rx_data  <= data_reg;
                        rx_valid <= 1'b1;
                    end
                    active  <= 1'b0;
                    bit_idx <= 4'd0;
                end
            end else
                baud_cnt <= baud_cnt + 16'd1;
        end
    end

endmodule
