// ============================================================================
// pc.v - HAEUN-16 Program Counter (프로그램 카운터)
// ============================================================================
// 기능 (clk 상승 에지, 우선순위: reset > jump > enable):
//   reset=1  : pc_out = 0
//   jump=1   : pc_out = jump_addr
//   enable=1 : pc_out = pc_out + 1
//   그 외    : pc_out 유지
// 합성: Verilog-2001, FPGA 이식 가능 (동기 순차 논리)
// ============================================================================

module pc (
    input  wire        clk,         // 시스템 클럭
    input  wire        reset,       // 동기 리셋 (1 = 0으로 초기화)
    input  wire        enable,      // 증가 허용 (1 = PC + 1)
    input  wire        jump,        // 분기 (1 = jump_addr로 이동)
    input  wire [15:0] jump_addr,   // 분기 목적 주소
    output reg  [15:0] pc_out       // 현재 PC 값
);

    always @(posedge clk) begin
        if (reset)
            pc_out <= 16'h0000;
        else if (jump)
            pc_out <= jump_addr;
        else if (enable)
            pc_out <= pc_out + 16'd1;
        // enable=0, jump=0, reset=0 이면 pc_out 유지
    end

endmodule
