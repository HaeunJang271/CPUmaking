// ============================================================================
// uart_fifo_rx.v - UART RX -> FIFO -> CPU IN (port 0)
// ============================================================================
// rd_en 펄스 시 FIFO pop. empty=1 이면 rd_data=0.
// ============================================================================

module uart_fifo_rx #(
    parameter FIFO_DEPTH = 16,
    parameter ADDR_BITS  = 4,
    parameter integer CLK_HZ   = 27_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    input  wire       rd_en,
    output wire [7:0] rd_data,
    output wire       empty,
    output wire       full
);

    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [ADDR_BITS:0] wr_ptr;
    reg [ADDR_BITS:0] rd_ptr;

    wire [ADDR_BITS:0] count = wr_ptr - rd_ptr;
    assign empty = (count == 0);
    assign full  = (count == FIFO_DEPTH);

    reg [7:0] data_out;

    wire [7:0] uart_byte;
    wire       uart_valid;

    uart_rx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_uart_rx (
        .clk      (clk),
        .reset    (reset),
        .rx       (rx),
        .rx_data  (uart_byte),
        .rx_valid (uart_valid)
    );

    assign rd_data = data_out;

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr   <= {ADDR_BITS+1{1'b0}};
            rd_ptr   <= {ADDR_BITS+1{1'b0}};
            data_out <= 8'h00;
        end else begin
            if (uart_valid && !full) begin
                fifo[wr_ptr[ADDR_BITS-1:0]] <= uart_byte;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (rd_en && !empty) begin
                data_out <= fifo[rd_ptr[ADDR_BITS-1:0]];
                rd_ptr   <= rd_ptr + 1'b1;
            end else if (!empty)
                data_out <= fifo[rd_ptr[ADDR_BITS-1:0]];
            else
                data_out <= 8'h00;
        end
    end

endmodule
