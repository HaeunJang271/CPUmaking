// ============================================================================
// svo_hdmi_soc.v - 컬러바 + CPU 연동 동적 텍스트 (screen_ram)
// ============================================================================

`timescale 1ns / 1ps
`include "hdmi/svo_defines.vh"

module svo_hdmi_soc (
    input  wire       sys_clk,
    input  wire       sys_reset,
    input  wire       clk,
    input  wire       resetn,
    input  wire       clk_pixel,
    input  wire       clk_5x_pixel,
    input  wire       locked,
    input  wire [15:0] cpu_r0,
    input  wire [15:0] cpu_r1,
    input  wire [15:0] cpu_pc,
    input  wire       cpu_screen_wr,
    input  wire [5:0] cpu_screen_addr,
    input  wire [7:0] cpu_screen_data,
    input  wire       stream_wr,
    input  wire [7:0] stream_data,
    input  wire       cursor_load,
    input  wire [5:0] cursor_val,
    input  wire [15:0] ram_peek_data,
    output wire [7:0] ram_peek_addr,
    output wire       tmds_clk_n,
    output wire       tmds_clk_p,
    output wire [2:0] tmds_d_n,
    output wire [2:0] tmds_d_p
);
    parameter ENABLE_STATUS        = 0;  // 1=레지스터 덤프, 0=CPU STORE 화면
    parameter SVO_MODE             = "640x480V";
    parameter SVO_FRAMERATE        = 60;
    parameter SVO_BITS_PER_PIXEL   = 24;
    parameter SVO_BITS_PER_RED     = 8;
    parameter SVO_BITS_PER_GREEN   = 8;
    parameter SVO_BITS_PER_BLUE    = 8;
    parameter SVO_BITS_PER_ALPHA   = 0;

    localparam [SVO_BITS_PER_PIXEL-1:0] white_pixval = ~0;
    localparam [SVO_BITS_PER_PIXEL-1:0] logo_pixval  = 24'hD4DCE8;  // 이미지와 비슷한 연회색

    wire vdma_tvalid;
    wire vdma_tready;
    wire [SVO_BITS_PER_PIXEL-1:0] vdma_tdata;
    wire [0:0] vdma_tuser;

    wire video_tvalid;
    wire video_tready;
    wire [SVO_BITS_PER_PIXEL-1:0] video_tdata;
    wire [0:0] video_tuser;

    wire term_out_tvalid;
    wire term_out_tready;
    wire [1:0] term_out_tdata;
    wire [0:0] term_out_tuser;

    wire logo_tvalid;
    wire logo_tready;
    wire [1:0] logo_tdata;
    wire [0:0] logo_tuser;

    wire base_tvalid;
    wire base_tready;
    wire [SVO_BITS_PER_PIXEL-1:0] base_tdata;
    wire [0:0] base_tuser;

    wire video_enc_tvalid;
    wire video_enc_tready;
    wire [SVO_BITS_PER_PIXEL-1:0] video_enc_tdata;
    wire [3:0] video_enc_tuser;

    wire [2:0] tmds_d;
    wire [2:0] tmds_d0, tmds_d1, tmds_d2, tmds_d3, tmds_d4;
    wire [2:0] tmds_d5, tmds_d6, tmds_d7, tmds_d8, tmds_d9;

    wire [5:0] ram_rd_addr;
    wire [7:0] ram_rd_data;
    wire [5:0] ram_msg_stop;
    wire       mirror_wr;
    wire [5:0] mirror_addr;
    wire [7:0] mirror_data;

    reg [4:0] resetn_clk_pixel_q;

    always @(posedge clk_pixel)
        resetn_clk_pixel_q <= {resetn_clk_pixel_q[3:0], resetn};

    wire clk_pixel_resetn = locked && resetn_clk_pixel_q[4];

    wire boot_done = (cpu_r1 == 16'd1);
    wire mirror_busy;

    screen_from_ram u_ram_mirror (
        .clk           (sys_clk),
        .reset         (sys_reset),
        .boot_done     (boot_done),
        .ram_peek_data (ram_peek_data),
        .ram_peek_addr (ram_peek_addr),
        .mirror_wr     (mirror_wr),
        .mirror_addr   (mirror_addr),
        .mirror_data   (mirror_data),
        .busy          (mirror_busy)
    );

    screen_bridge u_screen (
        .sys_clk      (sys_clk),
        .sys_reset    (sys_reset),
        .stream_wr    (stream_wr),
        .stream_data  (stream_data),
        .direct_wr    (cpu_screen_wr),
        .direct_addr  (cpu_screen_addr),
        .direct_data  (cpu_screen_data),
        .mirror_wr    (mirror_wr),
        .mirror_addr  (mirror_addr),
        .mirror_data  (mirror_data),
        .mirror_busy  (mirror_busy),
        .cursor_load  (cursor_load),
        .cursor_val   (cursor_val),
        .pix_clk      (clk_pixel),
        .pix_reset    (1'b0),
        .rd_addr      (ram_rd_addr),
        .rd_data      (ram_rd_data),
        .msg_stop     (ram_msg_stop)
    );

    svo_tcard #(`SVO_PASS_PARAMS) u_tcard (
        .clk            (clk_pixel),
        .resetn         (resetn),
        .out_axis_tvalid(vdma_tvalid),
        .out_axis_tready(vdma_tready),
        .out_axis_tdata (vdma_tdata),
        .out_axis_tuser (vdma_tuser)
    );

    svo_bitmap_logo #(`SVO_PASS_PARAMS) u_logo (
        .oclk            (clk_pixel),
        .resetn          (clk_pixel_resetn),
        .out_axis_tvalid (logo_tvalid),
        .out_axis_tready (logo_tready),
        .out_axis_tdata  (logo_tdata),
        .out_axis_tuser  (logo_tuser)
    );

    svo_overlay #(`SVO_PASS_PARAMS) u_logo_ov (
        .clk             (clk_pixel),
        .resetn          (clk_pixel_resetn),
        .enable          (1'b1),
        .in_axis_tvalid  (vdma_tvalid),
        .in_axis_tready  (vdma_tready),
        .in_axis_tdata   (vdma_tdata),
        .in_axis_tuser   (vdma_tuser),
        .over_axis_tvalid(logo_tvalid),
        .over_axis_tready(logo_tready),
        .over_axis_tdata (logo_pixval),
        .over_axis_tuser ({logo_tdata == 2'b10, logo_tuser}),
        .out_axis_tvalid (base_tvalid),
        .out_axis_tready (base_tready),
        .out_axis_tdata  (base_tdata),
        .out_axis_tuser  (base_tuser)
    );

    svo_live_text #(`SVO_PASS_PARAMS) u_term (
        .oclk            (clk_pixel),
        .resetn          (clk_pixel_resetn),
        .msg_stop_in     (ram_msg_stop),
        .msg_rd_addr     (ram_rd_addr),
        .msg_rdata       (ram_rd_data),
        .out_axis_tvalid (term_out_tvalid),
        .out_axis_tready (term_out_tready),
        .out_axis_tdata  (term_out_tdata),
        .out_axis_tuser  (term_out_tuser)
    );

    svo_overlay #(`SVO_PASS_PARAMS) u_overlay (
        .clk             (clk_pixel),
        .resetn          (clk_pixel_resetn),
        .enable          (1'b1),
        .in_axis_tvalid  (base_tvalid),
        .in_axis_tready  (base_tready),
        .in_axis_tdata   (base_tdata),
        .in_axis_tuser   (base_tuser),
        .over_axis_tvalid(term_out_tvalid),
        .over_axis_tready(term_out_tready),
        .over_axis_tdata (white_pixval),
        .over_axis_tuser ({term_out_tdata == 2'b10, term_out_tuser}),
        .out_axis_tvalid (video_tvalid),
        .out_axis_tready (video_tready),
        .out_axis_tdata  (video_tdata),
        .out_axis_tuser  (video_tuser)
    );

    svo_enc #(`SVO_PASS_PARAMS) u_enc (
        .clk             (clk_pixel),
        .resetn          (clk_pixel_resetn),
        .in_axis_tvalid  (video_tvalid),
        .in_axis_tready  (video_tready),
        .in_axis_tdata   (video_tdata),
        .in_axis_tuser   (video_tuser),
        .out_axis_tvalid (video_enc_tvalid),
        .out_axis_tready (video_enc_tready),
        .out_axis_tdata  (video_enc_tdata),
        .out_axis_tuser  (video_enc_tuser)
    );

    assign video_enc_tready = 1'b1;

    svo_tmds u_tmds_r (
        .clk(clk_pixel), .resetn(clk_pixel_resetn),
        .de(!video_enc_tuser[3]), .ctrl(video_enc_tuser[2:1]),
        .din(video_enc_tdata[23:16]),
        .dout({tmds_d9[0], tmds_d8[0], tmds_d7[0], tmds_d6[0], tmds_d5[0],
               tmds_d4[0], tmds_d3[0], tmds_d2[0], tmds_d1[0], tmds_d0[0]})
    );

    svo_tmds u_tmds_g (
        .clk(clk_pixel), .resetn(clk_pixel_resetn),
        .de(!video_enc_tuser[3]), .ctrl(2'b0),
        .din(video_enc_tdata[15:8]),
        .dout({tmds_d9[1], tmds_d8[1], tmds_d7[1], tmds_d6[1], tmds_d5[1],
               tmds_d4[1], tmds_d3[1], tmds_d2[1], tmds_d1[1], tmds_d0[1]})
    );

    svo_tmds u_tmds_b (
        .clk(clk_pixel), .resetn(clk_pixel_resetn),
        .de(!video_enc_tuser[3]), .ctrl(2'b0),
        .din(video_enc_tdata[7:0]),
        .dout({tmds_d9[2], tmds_d8[2], tmds_d7[2], tmds_d6[2], tmds_d5[2],
               tmds_d4[2], tmds_d3[2], tmds_d2[2], tmds_d1[2], tmds_d0[2]})
    );

    OSER10 tmds_serdes [2:0] (
        .Q   (tmds_d),
        .D0  (tmds_d0), .D1(tmds_d1), .D2(tmds_d2), .D3(tmds_d3), .D4(tmds_d4),
        .D5  (tmds_d5), .D6(tmds_d6), .D7(tmds_d7), .D8(tmds_d8), .D9(tmds_d9),
        .PCLK(clk_pixel), .FCLK(clk_5x_pixel), .RESET(~clk_pixel_resetn)
    );

    ELVDS_OBUF tmds_bufds [3:0] (
        .I ({clk_pixel, tmds_d}),
        .O ({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
    );

endmodule

// 합성 .prj 캐시에 누락돼도 svo_hdmi_soc 와 함께 파싱됨 (Reload All 불필요)
`include "hdmi/svo_bitmap_logo.v"
`include "screen_from_ram.v"
