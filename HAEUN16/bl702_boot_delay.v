// ============================================================================
// bl702_boot_delay.v - BL702 USB-UART 준비 대기 후 CPU 부트
// ============================================================================
// Tang Nano 9K: S1 리셋 직후 FPGA가 UART를 쏘면 BL702 브리지가 아직
// 준비 안 됐을 수 있음. 이 구간에서 CPU/UART를 홀드.
// ============================================================================

module bl702_boot_delay #(
    parameter integer CLK_HZ    = 27_000_000,
    parameter integer DELAY_MS  = 2000
)(
    input  wire clk,
    input  wire rst_n,       // 동기화된 active-low (버튼 놓음 = 1)
    output wire hold_active  // 1이면 CPU/UART 리셋 유지
);

    localparam integer TICKS = (CLK_HZ / 1000) * DELAY_MS;
    localparam integer CNT_W = $clog2(TICKS + 1);

    reg [CNT_W-1:0] cnt;
    reg             holding;

    assign hold_active = holding;

    always @(posedge clk) begin
        if (!rst_n) begin
            holding <= 1'b1;
            cnt     <= TICKS[CNT_W-1:0];
        end else if (holding) begin
            if (cnt == {CNT_W{1'b0}})
                holding <= 1'b0;
            else
                cnt <= cnt - 1'b1;
        end
    end

endmodule
