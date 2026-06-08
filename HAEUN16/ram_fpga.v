// ============================================================================
// ram_fpga.v - HAEUN-16 FPGA용 RAM (256 words x 16bit)
// ============================================================================
// Tang Nano 9K (GW1NR-9) BSRAM 용량에 맞춘 축소 메모리
// 포트는 ram.v 와 동일 -> cpu.v 에서 ram 대신 인스턴스
// 주소: address[7:0] 사용 (0~255), address[15:8] 무시
// 프로그램: boot.asm (UART 부트 펌웨어) — demo 로 바꾸려면 programs/demo.mi 참고
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
        memory[0] = 16'h8003;   // JMP BOOT
        memory[1] = 16'hC000;   // SEND: OUT R0,0
        memory[2] = 16'hB000;   // RET
        memory[3] = 16'h1048;   // BOOT: LOAD R0,'H'
        memory[4] = 16'hA001;   // CALL SEND
        memory[5] = 16'h1041;
        memory[6] = 16'hA001;
        memory[7] = 16'h1045;
        memory[8] = 16'hA001;
        memory[9] = 16'h1055;
        memory[10] = 16'hA001;
        memory[11] = 16'h104E;
        memory[12] = 16'hA001;
        memory[13] = 16'h102D;
        memory[14] = 16'hA001;
        memory[15] = 16'h1031;
        memory[16] = 16'hA001;
        memory[17] = 16'h1036;
        memory[18] = 16'hA001;
        memory[19] = 16'h1020;
        memory[20] = 16'hA001;
        memory[21] = 16'h1042;
        memory[22] = 16'hA001;
        memory[23] = 16'h106F;
        memory[24] = 16'hA001;
        memory[25] = 16'h106F;
        memory[26] = 16'hA001;
        memory[27] = 16'h1074;
        memory[28] = 16'hA001;
        memory[29] = 16'h100A;
        memory[30] = 16'hA001;
        memory[31] = 16'h1401;   // LOAD R1,1 (done)
        memory[32] = 16'h103E;   // PROMPT: LOAD R0,'>'
        memory[33] = 16'hA001;
        memory[34] = 16'h1020;
        memory[35] = 16'hA001;
        memory[36] = 16'h8020;   // JMP PROMPT
    end

    always @(posedge clk) begin
        if (write_enable)
            memory[addr] <= data_in;
        data_out <= memory[addr];
    end

endmodule
