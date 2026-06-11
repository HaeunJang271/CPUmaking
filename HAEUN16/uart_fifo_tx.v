// ============================================================================
// uart_fifo_tx.v - CPU OUT → FIFO → uart_tx (바이트 유실 방지)
// ============================================================================

module uart_fifo_tx #(
    parameter FIFO_DEPTH = 16,
    parameter ADDR_BITS  = 4,
    parameter integer CLK_HZ   = 27_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       wr_en,
    input  wire [7:0] wr_data,
    output wire       full,
    output wire       tx,
    output wire       busy
);

    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [ADDR_BITS:0] wr_ptr;
    reg [ADDR_BITS:0] rd_ptr;

    wire [ADDR_BITS:0] count = wr_ptr - rd_ptr;
    assign full = (count == FIFO_DEPTH);

    reg [7:0] tx_data;
    reg       tx_send;
    reg       byte_ready;

    uart_tx #(
        .CLK_HZ   (CLK_HZ),
        .BAUDRATE (BAUDRATE)
    ) u_uart (
        .clk     (clk),
        .reset   (reset),
        .data_in (tx_data),
        .send    (tx_send),
        .tx      (tx),
        .busy    (busy)
    );

    always @(posedge clk) begin
        tx_send <= 1'b0;

        if (reset) begin
            wr_ptr     <= {ADDR_BITS+1{1'b0}};
            rd_ptr     <= {ADDR_BITS+1{1'b0}};
            byte_ready <= 1'b0;
            tx_data    <= 8'h00;
        end else begin
            if (wr_en && !full) begin
                fifo[wr_ptr[ADDR_BITS-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // UART idle + queued byte → 1사이클 send 펄스
            if (!busy && byte_ready) begin
                tx_send <= 1'b1;
                byte_ready <= 1'b0;
            end else if (!byte_ready && !busy && count != 0) begin
                tx_data <= fifo[rd_ptr[ADDR_BITS-1:0]];
                rd_ptr <= rd_ptr + 1'b1;
                byte_ready <= 1'b1;
            end
        end
    end

endmodule
