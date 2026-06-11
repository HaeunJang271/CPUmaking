// ============================================================================
// top_hdmi_colorbars.v - Tang Nano 9K HDMI SMPTE 컬러바 테스트
// ============================================================================
// Gowin Top: top_hdmi_colorbars
// 640x480@60 컬러바 + 텍스트 오버레이. HAEUN-16 CPU와 별도 비트스트림.
// ============================================================================

module top_hdmi_colorbars (
    input  wire       sys_clk,     // 27MHz pin 52
    input  wire       sys_rst_n,  // pin 4 (active-low)
    output wire       tmds_clk_n,
    output wire       tmds_clk_p,
    output wire [2:0] tmds_d_n,
    output wire [2:0] tmds_d_p
);

    wire       clk_p5;
    wire       clk_p;
    wire       pll_lock;
    wire       sys_resetn;

    Gowin_rPLL u_pll (
        .clkin (sys_clk),
        .clkout(clk_p5),
        .lock  (pll_lock)
    );

    Gowin_CLKDIV u_div_5 (
        .clkout (clk_p),
        .hclkin (clk_p5),
        .resetn (pll_lock)
    );

    hdmi_reset_sync u_reset_sync (
        .clk       (clk_p),
        .ext_reset (sys_rst_n & pll_lock),
        .resetn    (sys_resetn)
    );

    svo_hdmi_text u_hdmi (
        .clk          (clk_p),
        .resetn       (sys_resetn),
        .clk_pixel    (clk_p),
        .clk_5x_pixel (clk_p5),
        .locked       (pll_lock),
        .tmds_clk_n   (tmds_clk_n),
        .tmds_clk_p   (tmds_clk_p),
        .tmds_d_n     (tmds_d_n),
        .tmds_d_p     (tmds_d_p)
    );

endmodule

module hdmi_reset_sync (
    input  wire clk,
    input  wire ext_reset,
    output wire resetn
);
    reg [3:0] reset_cnt = 4'd0;

    always @(posedge clk or negedge ext_reset) begin
        if (!ext_reset)
            reset_cnt <= 4'd0;
        else
            reset_cnt <= reset_cnt + !resetn;
    end

    assign resetn = &reset_cnt;
endmodule
