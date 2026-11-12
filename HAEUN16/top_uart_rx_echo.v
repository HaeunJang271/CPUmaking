// ============================================================================
// top_uart_rx_echo.v - UART RX 하드웨어 스모크 (CPU 없음, 수신 즉시 에코)
// ============================================================================
// ext_uart cst (pin 37=TX, 38=RX) 로 Program 후 COM7 miniterm:
//   아무 키 → 같은 글자가 돌아오면 RX 배선 OK
//   LED[0]: 수신할 때마다 토글
//   LED[5:1]: 마지막 수신 바이트 하위 5비트
// ============================================================================

module top_uart_rx_echo (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    output wire [5:0] led,
    output wire       uart_tx,
    input  wire       uart_rx
);

    reg rst_sync1;
    reg rst_sync2;

    always @(posedge sys_clk) begin
        rst_sync1 <= sys_rst_n;
        rst_sync2 <= rst_sync1;
    end

    wire reset = ~rst_sync2;

    wire [7:0] rx_byte;
    wire       rx_valid;

    uart_rx #(
        .CLK_HZ   (27_000_000),
        .BAUDRATE (115200)
    ) u_rx (
        .clk      (sys_clk),
        .reset    (reset),
        .rx       (uart_rx),
        .rx_data  (rx_byte),
        .rx_valid (rx_valid)
    );

    wire       tx_full;
    reg        tx_wr;
    reg [7:0]  tx_data;

    uart_fifo_tx #(
        .CLK_HZ   (27_000_000),
        .BAUDRATE (115200)
    ) u_tx (
        .clk     (sys_clk),
        .reset   (reset),
        .wr_en   (tx_wr),
        .wr_data (tx_data),
        .full    (tx_full),
        .tx      (uart_tx),
        .busy    ()
    );

    reg        led0;
    reg [4:0]  last_nibble;

    always @(posedge sys_clk) begin
        tx_wr <= 1'b0;

        if (reset) begin
            led0        <= 1'b0;
            last_nibble <= 5'd0;
        end else if (rx_valid && !tx_full) begin
            tx_wr       <= 1'b1;
            tx_data     <= rx_byte;
            led0        <= ~led0;
            last_nibble <= rx_byte[4:0];
        end
    end

    assign led = {last_nibble, led0};

endmodule
