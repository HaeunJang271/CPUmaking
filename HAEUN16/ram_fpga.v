// ============================================================================
// ram_fpga.v - HAEUN-16 FPGA용 RAM (512 words x 16bit)
// ============================================================================
// Tang Nano 9K (GW1NR-9) BSRAM 용량에 맞춘 축소 메모리
// 포트는 ram.v 와 동일 -> cpu.v 에서 ram 대신 인스턴스
// 주소: address[8:0] 사용 (0~511), address[15:9] 무시
// 프로그램: os.asm (HAEUN-OS v0.1 HDMI) — 갱신: python tools/gen_ram_os.py
// OS 복원: python tools/asm.py programs/os.asm --verilog
// 합성: Gowin BRAM 추론 + initial (소용량)
// ============================================================================

module ram_fpga (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [15:0] address,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out,
    input  wire        peek_clk,
    input  wire [7:0]  peek_addr,
    output reg  [15:0] peek_data
);

    // 512 x 16bit (8 Kbit) - Tang Nano 9K BSRAM 에 여유 있음
    reg [15:0] memory [0:511];

    wire [8:0] addr = address[8:0];

    integer i;

    // 시뮬/FPGA: 테스트 프로그램 + 나머지 0
    // Gowin: 동일 내용을 program.mi 로 BRAM init 가능
    initial begin
        for (i = 0; i < 512; i = i + 1)
            memory[i] = 16'h0000;
        memory[0] = 16'h8020;
        memory[1] = 16'hC000;
        memory[2] = 16'hC001;
        memory[3] = 16'hB000;
        memory[4] = 16'hD000;
        memory[5] = 16'h9004;
        memory[6] = 16'hB000;
        memory[7] = 16'h100A;
        memory[8] = 16'hA001;
        memory[9] = 16'hB000;
        memory[10] = 16'h103E;
        memory[11] = 16'hA001;
        memory[12] = 16'h1020;
        memory[13] = 16'hA001;
        memory[14] = 16'hB000;
        memory[15] = 16'h1052;
        memory[16] = 16'h20F7;
        memory[17] = 16'h1045;
        memory[18] = 16'h20F8;
        memory[19] = 16'h1041;
        memory[20] = 16'h20F9;
        memory[21] = 16'h1044;
        memory[22] = 16'h20FA;
        memory[23] = 16'h1059;
        memory[24] = 16'h20FB;
        memory[25] = 16'h100A;
        memory[26] = 16'h20FC;
        memory[27] = 16'h100A;
        memory[28] = 16'h20FD;
        memory[29] = 16'h1000;
        memory[30] = 16'h20FE;
        memory[31] = 16'hB000;
        memory[32] = 16'h1048;
        memory[33] = 16'hA001;
        memory[34] = 16'h1041;
        memory[35] = 16'hA001;
        memory[36] = 16'h1045;
        memory[37] = 16'hA001;
        memory[38] = 16'h1055;
        memory[39] = 16'hA001;
        memory[40] = 16'h104E;
        memory[41] = 16'hA001;
        memory[42] = 16'h102D;
        memory[43] = 16'hA001;
        memory[44] = 16'h104F;
        memory[45] = 16'hA001;
        memory[46] = 16'h1053;
        memory[47] = 16'hA001;
        memory[48] = 16'h1020;
        memory[49] = 16'hA001;
        memory[50] = 16'h1076;
        memory[51] = 16'hA001;
        memory[52] = 16'h1030;
        memory[53] = 16'hA001;
        memory[54] = 16'h102E;
        memory[55] = 16'hA001;
        memory[56] = 16'h1031;
        memory[57] = 16'hA001;
        memory[58] = 16'hA007;
        memory[59] = 16'hA00F;
        memory[60] = 16'h1015;
        memory[61] = 16'hC002;
        memory[62] = 16'h1401;
        memory[63] = 16'hA00A;
        memory[64] = 16'hA004;
        memory[65] = 16'h1400;
        memory[66] = 16'h3400;
        memory[67] = 16'h1868;
        memory[68] = 16'h1000;
        memory[69] = 16'h3100;
        memory[70] = 16'h4200;
        memory[71] = 16'h9058;
        memory[72] = 16'h1000;
        memory[73] = 16'h3100;
        memory[74] = 16'h1876;
        memory[75] = 16'h4200;
        memory[76] = 16'h909E;
        memory[77] = 16'h1000;
        memory[78] = 16'h3100;
        memory[79] = 16'h1865;
        memory[80] = 16'h4200;
        memory[81] = 16'h90CB;
        memory[82] = 16'h1000;
        memory[83] = 16'h3100;
        memory[84] = 16'h1872;
        memory[85] = 16'h4200;
        memory[86] = 16'h90E9;
        memory[87] = 16'h8007;
        memory[88] = 16'hA004;
        memory[89] = 16'h1865;
        memory[90] = 16'h4200;
        memory[91] = 16'h905D;
        memory[92] = 16'h8007;
        memory[93] = 16'hA004;
        memory[94] = 16'h186C;
        memory[95] = 16'h4200;
        memory[96] = 16'h9062;
        memory[97] = 16'h8007;
        memory[98] = 16'hA004;
        memory[99] = 16'h1870;
        memory[100] = 16'h4200;
        memory[101] = 16'h9067;
        memory[102] = 16'h8007;
        memory[103] = 16'hA004;
        memory[104] = 16'h180A;
        memory[105] = 16'h4200;
        memory[106] = 16'h906C;
        memory[107] = 16'h8007;
        memory[108] = 16'h1068;
        memory[109] = 16'hA001;
        memory[110] = 16'h1065;
        memory[111] = 16'hA001;
        memory[112] = 16'h106C;
        memory[113] = 16'hA001;
        memory[114] = 16'h1070;
        memory[115] = 16'hA001;
        memory[116] = 16'h1020;
        memory[117] = 16'hA001;
        memory[118] = 16'h1065;
        memory[119] = 16'hA001;
        memory[120] = 16'h1063;
        memory[121] = 16'hA001;
        memory[122] = 16'h1068;
        memory[123] = 16'hA001;
        memory[124] = 16'h106F;
        memory[125] = 16'hA001;
        memory[126] = 16'h1020;
        memory[127] = 16'hA001;
        memory[128] = 16'h1076;
        memory[129] = 16'hA001;
        memory[130] = 16'h1065;
        memory[131] = 16'hA001;
        memory[132] = 16'h1072;
        memory[133] = 16'hA001;
        memory[134] = 16'h1073;
        memory[135] = 16'hA001;
        memory[136] = 16'h1069;
        memory[137] = 16'hA001;
        memory[138] = 16'h106F;
        memory[139] = 16'hA001;
        memory[140] = 16'h106E;
        memory[141] = 16'hA001;
        memory[142] = 16'h1020;
        memory[143] = 16'hA001;
        memory[144] = 16'h1072;
        memory[145] = 16'hA001;
        memory[146] = 16'h1065;
        memory[147] = 16'hA001;
        memory[148] = 16'h1062;
        memory[149] = 16'hA001;
        memory[150] = 16'h106F;
        memory[151] = 16'hA001;
        memory[152] = 16'h106F;
        memory[153] = 16'hA001;
        memory[154] = 16'h1074;
        memory[155] = 16'hA001;
        memory[156] = 16'hA007;
        memory[157] = 16'h803F;
        memory[158] = 16'hA004;
        memory[159] = 16'h1865;
        memory[160] = 16'h4200;
        memory[161] = 16'h90A3;
        memory[162] = 16'h8007;
        memory[163] = 16'hA004;
        memory[164] = 16'h1872;
        memory[165] = 16'h4200;
        memory[166] = 16'h90A8;
        memory[167] = 16'h8007;
        memory[168] = 16'hA004;
        memory[169] = 16'h1873;
        memory[170] = 16'h4200;
        memory[171] = 16'h90AD;
        memory[172] = 16'h8007;
        memory[173] = 16'hA004;
        memory[174] = 16'h1869;
        memory[175] = 16'h4200;
        memory[176] = 16'h90B2;
        memory[177] = 16'h8007;
        memory[178] = 16'hA004;
        memory[179] = 16'h186F;
        memory[180] = 16'h4200;
        memory[181] = 16'h90B7;
        memory[182] = 16'h8007;
        memory[183] = 16'hA004;
        memory[184] = 16'h186E;
        memory[185] = 16'h4200;
        memory[186] = 16'h90BC;
        memory[187] = 16'h8007;
        memory[188] = 16'hA004;
        memory[189] = 16'h180A;
        memory[190] = 16'h4200;
        memory[191] = 16'h90C1;
        memory[192] = 16'h8007;
        memory[193] = 16'h1076;
        memory[194] = 16'hA001;
        memory[195] = 16'h1030;
        memory[196] = 16'hA001;
        memory[197] = 16'h102E;
        memory[198] = 16'hA001;
        memory[199] = 16'h1031;
        memory[200] = 16'hA001;
        memory[201] = 16'hA007;
        memory[202] = 16'h803F;
        memory[203] = 16'hA004;
        memory[204] = 16'h1863;
        memory[205] = 16'h4200;
        memory[206] = 16'h90D0;
        memory[207] = 16'h8007;
        memory[208] = 16'hA004;
        memory[209] = 16'h1868;
        memory[210] = 16'h4200;
        memory[211] = 16'h90D5;
        memory[212] = 16'h8007;
        memory[213] = 16'hA004;
        memory[214] = 16'h186F;
        memory[215] = 16'h4200;
        memory[216] = 16'h90DA;
        memory[217] = 16'h8007;
        memory[218] = 16'hA004;
        memory[219] = 16'h1C00;
        memory[220] = 16'h3C00;
        memory[221] = 16'h180A;
        memory[222] = 16'h1000;
        memory[223] = 16'h3300;
        memory[224] = 16'h4200;
        memory[225] = 16'h90E7;
        memory[226] = 16'h1000;
        memory[227] = 16'h3300;
        memory[228] = 16'hC000;
        memory[229] = 16'hC001;
        memory[230] = 16'h80DA;
        memory[231] = 16'hA007;
        memory[232] = 16'h803F;
        memory[233] = 16'hA004;
        memory[234] = 16'h1865;
        memory[235] = 16'h4200;
        memory[236] = 16'h90EE;
        memory[237] = 16'h8007;
        memory[238] = 16'hA004;
        memory[239] = 16'h1862;
        memory[240] = 16'h4200;
        memory[241] = 16'h90F3;
        memory[242] = 16'h8007;
        memory[243] = 16'hA004;
        memory[244] = 16'h186F;
        memory[245] = 16'h4200;
        memory[246] = 16'h90F8;
        memory[247] = 16'h8007;
        memory[248] = 16'hA004;
        memory[249] = 16'h186F;
        memory[250] = 16'h4200;
        memory[251] = 16'h90FD;
        memory[252] = 16'h8007;
        memory[253] = 16'hA004;
        memory[254] = 16'h1874;
        memory[255] = 16'h4200;
        memory[256] = 16'h9002;
        memory[257] = 16'h8007;
        memory[258] = 16'hA004;
        memory[259] = 16'h180A;
        memory[260] = 16'h4200;
        memory[261] = 16'h9020;
        memory[262] = 16'h8007;
        memory[263] = 16'h103F;
        memory[264] = 16'hA001;
        memory[265] = 16'hA007;
        memory[266] = 16'h803F;
    end

    // Gowin GW1NR-9C DPB: WRITE_MODE0=2'b10(RBW) 미지원 -> write-through(2'b01)
    always @(posedge clk) begin
        if (write_enable) begin
            memory[addr] <= data_in;
            data_out     <= data_in;
        end else
            data_out <= memory[addr];
    end

    // peek 포트: read-only (port B)
    always @(posedge peek_clk) begin
        peek_data <= memory[peek_addr];
    end

endmodule
