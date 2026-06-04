// ============================================================================
// ram_fpga.v - HAEUN-16 FPGA용 RAM (256 words x 16bit)
// ============================================================================
// Tang Nano 9K (GW1NR-9) BSRAM 용량에 맞춘 축소 메모리
// 포트는 ram.v 와 동일 -> cpu.v 에서 ram 대신 인스턴스
// 주소: address[7:0] 사용 (0~255), address[15:8] 무시
// 프로그램: 주소 0~2 에 통합 테스트 기계어 초기화
// 합성: Gowin BRAM 추론 + initial (소용량)
// ============================================================================

module ram_fpga (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [15:0] address,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out
);

    // 256 x 16bit (4 Kbit) - Tang Nano 9K BSRAM 에 여유 있음
    reg [15:0] memory [0:255];

    wire [7:0] addr = address[7:0];

    integer i;

    // 시뮬/FPGA: 테스트 프로그램 + 나머지 0
    // Gowin: 동일 내용을 program.mi 로 BRAM init 가능
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 16'h0000;
        memory[0] = 16'h1005;   // LOAD R0, 5
        memory[1] = 16'h1403;   // LOAD R1, 3
        memory[2] = 16'h3100;   // ADD  R0, R1
    end

    always @(posedge clk) begin
        if (write_enable)
            memory[addr] <= data_in;
        data_out <= memory[addr];
    end

endmodule
