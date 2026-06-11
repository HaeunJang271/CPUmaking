// ============================================================================
// top_haeun16_soc.v - HAEUN-16 CPU + HDMI 상태 화면 (Tang Nano 9K)
// ============================================================================
// CPU: HAEUN-OS v0.1 @ 27MHz, LED + UART
// HDMI: OUT port 1 터미널 + 컬러바 (UART 와 동시 출력)
// ============================================================================

module top_haeun16_soc (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    output wire [5:0] led,
    output wire       uart_tx,
    input  wire       uart_rx,
    output wire       tmds_clk_n,
    output wire       tmds_clk_p,
    output wire [2:0] tmds_d_n,
    output wire [2:0] tmds_d_p
);

    reg rst_sync1;
    reg rst_sync2;

    always @(posedge sys_clk) begin
        rst_sync1 <= sys_rst_n;
        rst_sync2 <= rst_sync1;
    end

    wire bl702_hold;

    bl702_boot_delay #(
        .CLK_HZ   (27_000_000),
        .DELAY_MS (2000)
    ) u_bl702_delay (
        .clk         (sys_clk),
        .rst_n       (rst_sync2),
        .hold_active (bl702_hold)
    );

    wire sys_reset = ~rst_sync2 | bl702_hold;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;
    wire        io_out_strobe;
    wire [7:0]  io_out_port;
    wire [7:0]  io_out_data;
    wire        io_in_strobe;
    wire [7:0]  io_in_port;
    wire [7:0]  io_in_data;
    wire        screen_wr;
    wire [5:0]  screen_addr;
    wire [7:0]  screen_data;
    wire        stream_wr;
    wire [7:0]  stream_data;
    wire        cursor_load;
    wire [5:0]  cursor_val;
    wire [7:0]  ram_peek_addr;
    wire [15:0] ram_peek_data;
    wire       clk_p5;
    wire       clk_p;
    wire       pll_lock;
    wire       hdmi_resetn;

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

    hdmi_reset_sync u_hdmi_rst (
        .clk       (clk_p),
        .ext_reset (sys_rst_n & pll_lock),
        .resetn    (hdmi_resetn)
    );

    cpu u_cpu (
        .clk           (sys_clk),
        .reset         (sys_reset),
        .r0            (r0),
        .r1            (r1),
        .r2            (r2),
        .r3            (r3),
        .pc_out        (pc_out),
        .io_out_strobe (io_out_strobe),
        .io_out_port   (io_out_port),
        .io_out_data   (io_out_data),
        .io_in_strobe  (io_in_strobe),
        .io_in_port    (io_in_port),
        .io_in_data    (io_in_data),
        .screen_wr     (screen_wr),
        .screen_addr   (screen_addr),
        .screen_data   (screen_data),
        .peek_clk      (sys_clk),
        .peek_addr     (ram_peek_addr),
        .peek_data     (ram_peek_data)
    );

    wire uart_wr  = io_out_strobe && (io_out_port == 8'd0);
    wire screen_io_wr = io_out_strobe && (io_out_port == 8'd1);
    assign cursor_load = io_out_strobe && (io_out_port == 8'd2);
    assign cursor_val  = io_out_data[5:0];

    screen_io_tx u_screen_io (
        .clk         (sys_clk),
        .reset       (sys_reset),
        .wr_en       (screen_io_wr),
        .wr_data     (io_out_data),
        .stream_wr   (stream_wr),
        .stream_data (stream_data)
    );

    uart_path_bl702 u_uart_tx (
        .clk     (sys_clk),
        .reset   (sys_reset),
        .wr_en   (uart_wr),
        .wr_data (io_out_data),
        .full    (),
        .busy    (),
        .tx      (uart_tx)
    );

    wire uart_rd = io_in_strobe && (io_in_port == 8'd0);

    uart_fifo_rx u_uart_rx (
        .clk     (sys_clk),
        .reset   (sys_reset),
        .rx      (uart_rx),
        .rd_en   (uart_rd),
        .rd_data (io_in_data),
        .empty   (),
        .full    ()
    );

    wire done = (r1 == 16'd1);
    assign led = done ? 6'b000000 : ~r0[5:0];

    svo_hdmi_soc u_hdmi (
        .sys_clk          (sys_clk),
        .sys_reset        (sys_reset),
        .clk              (clk_p),
        .resetn           (hdmi_resetn),
        .clk_pixel        (clk_p),
        .clk_5x_pixel     (clk_p5),
        .locked           (pll_lock),
        .cpu_r0           (r0),
        .cpu_r1           (r1),
        .cpu_pc           (pc_out),
        .cpu_screen_wr    (screen_wr),
        .cpu_screen_addr  (screen_addr),
        .cpu_screen_data  (screen_data),
        .stream_wr        (stream_wr),
        .stream_data      (stream_data),
        .cursor_load      (cursor_load),
        .cursor_val       (cursor_val),
        .ram_peek_data    (ram_peek_data),
        .ram_peek_addr    (ram_peek_addr),
        .tmds_clk_n       (tmds_clk_n),
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
