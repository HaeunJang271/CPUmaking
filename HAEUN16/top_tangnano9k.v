// ============================================================================
// top_tangnano9k.v - Tang Nano 9K (GW1NR-9) 탑 모듈
// ============================================================================
// 보드: 27MHz sys_clk, active-low LED, active-low reset button (S1, pin 4)
// CPU: HAEUN-16 + UART TX (pin 17, 115200 8N1)
// LED: R1=1 (boot done) -> 6 LED ON, else r0[5:0] 패턴
// ============================================================================

module top_tangnano9k (
    input  wire       sys_clk,     // 27MHz, pin 52
    input  wire       sys_rst_n,   // S1 버튼, pin 4
    output wire [5:0] led,         // pin 10,11,13,14,15,16
    output wire       uart_tx      // pin 17
);

    reg rst_sync1;
    reg rst_sync2;

    always @(posedge sys_clk) begin
        rst_sync1 <= sys_rst_n;
        rst_sync2 <= rst_sync1;
    end

    wire cpu_reset = ~rst_sync2;

    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire [15:0] pc_out;
    wire        io_out_strobe;
    wire [7:0]  io_out_port;
    wire [7:0]  io_out_data;

    cpu u_cpu (
        .clk           (sys_clk),
        .reset         (cpu_reset),
        .r0            (r0),
        .r1            (r1),
        .r2            (r2),
        .r3            (r3),
        .pc_out        (pc_out),
        .io_out_strobe (io_out_strobe),
        .io_out_port   (io_out_port),
        .io_out_data   (io_out_data),
        .io_in_data    (8'h00)
    );

    wire        uart_busy;
    wire        uart_send = io_out_strobe && (io_out_port == 8'd0) && !uart_busy;

    uart_tx u_uart (
        .clk     (sys_clk),
        .reset   (cpu_reset),
        .data_in (io_out_data),
        .send    (uart_send),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    wire done = (r1 == 16'd1);

    assign led = done ? 6'b000000 : ~r0[5:0];

endmodule
