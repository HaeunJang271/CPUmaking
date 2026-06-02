// ============================================================================
// ram.v - HAEUN-16 64KB RAM (65536 words x 16bit)
// ============================================================================
// 기능 (clk 상승 에지):
//   write_enable=1 : memory[address] <= data_in (쓰기)
//   항상           : data_out <= memory[address] (동기 읽기)
// 용량: 65536 word (address[15:0]), word 크기 16bit (= 128KB 비트, 64KB 바이트 표기 관례)
// 합성: Verilog-2001, FPGA Block RAM으로 추론 가능
// ============================================================================

module ram (
    input  wire        clk,           // 시스템 클럭
    input  wire        write_enable,  // 쓰기 허용 (1 = 쓰기)
    input  wire [15:0] address,       // 워드 주소 (0 ~ 65535)
    input  wire [15:0] data_in,       // 쓰기 데이터
    output reg  [15:0] data_out       // 읽기 데이터 (1클럭 지연)
);

    // 65536 x 16bit 메모리 배열
    reg [15:0] memory [0:65535];

    integer i;

    // 시뮬레이션 초기값 0 (읽기 전 예측 가능한 상태)
    initial begin
        for (i = 0; i < 65536; i = i + 1)
            memory[i] = 16'h0000;
    end

    // 동기 읽기/쓰기
    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= data_in;
        data_out <= memory[address];
    end

endmodule
