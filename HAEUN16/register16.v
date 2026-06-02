// ============================================================================
// register16.v - HAEUN-16 16비트 레지스터
// ============================================================================
// 기능:
//   load=1  : clk 상승 에지에서 data_in 저장
//   load=0  : 값 유지
//   reset=1 : clk 상승 에지에서 0으로 초기화 (reset 우선)
// 합성: Verilog-2001, FPGA 이식 가능 (동기 순차 논리)
// ============================================================================

module register16 (
    input  wire        clk,       // 시스템 클럭
    input  wire        reset,     // 동기 리셋 (1 = 0으로 초기화)
    input  wire        load,      // 적재 신호 (1 = data_in 저장)
    input  wire [15:0] data_in,   // 입력 데이터
    output reg  [15:0] data_out   // 저장된 출력 데이터
);

    // clk 상승 에지에서 reset / load 처리
    always @(posedge clk) begin
        if (reset)
            data_out <= 16'h0000;
        else if (load)
            data_out <= data_in;
        // load=0, reset=0 이면 data_out 유지 (할당 없음)
    end

endmodule
