// ============================================================================
// ram_fpga.v - HAEUN-16 FPGA용 RAM (256 words x 16bit)
// ============================================================================
// Tang Nano 9K (GW1NR-9) BSRAM 용량에 맞춘 축소 메모리
// 포트는 ram.v 와 동일 -> cpu.v 에서 ram 대신 인스턴스
// 주소: address[7:0] 사용 (0~255), address[15:8] 무시
// 프로그램: os.asm (HAEUN-OS v0.1) — 갱신: python tools/asm.py programs/os.asm --verilog
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
        memory[0] = 16'h800E;
        memory[1] = 16'hC000;
        memory[2] = 16'hB000;
        memory[3] = 16'hD000;
        memory[4] = 16'h9003;
        memory[5] = 16'hB000;
        memory[6] = 16'h100A;
        memory[7] = 16'hA001;
        memory[8] = 16'hB000;
        memory[9] = 16'h103E;
        memory[10] = 16'hA001;
        memory[11] = 16'h1020;
        memory[12] = 16'hA001;
        memory[13] = 16'hB000;
        memory[14] = 16'h1048;
        memory[15] = 16'hA001;
        memory[16] = 16'h1041;
        memory[17] = 16'hA001;
        memory[18] = 16'h1045;
        memory[19] = 16'hA001;
        memory[20] = 16'h1055;
        memory[21] = 16'hA001;
        memory[22] = 16'h104E;
        memory[23] = 16'hA001;
        memory[24] = 16'h102D;
        memory[25] = 16'hA001;
        memory[26] = 16'h104F;
        memory[27] = 16'hA001;
        memory[28] = 16'h1053;
        memory[29] = 16'hA001;
        memory[30] = 16'h1020;
        memory[31] = 16'hA001;
        memory[32] = 16'h1076;
        memory[33] = 16'hA001;
        memory[34] = 16'h1030;
        memory[35] = 16'hA001;
        memory[36] = 16'h102E;
        memory[37] = 16'hA001;
        memory[38] = 16'h1031;
        memory[39] = 16'hA001;
        memory[40] = 16'hA006;
        memory[41] = 16'h1401;
        memory[42] = 16'hA009;
        memory[43] = 16'hA003;
        memory[44] = 16'h1400;
        memory[45] = 16'h3400;
        memory[46] = 16'h1868;
        memory[47] = 16'h1000;
        memory[48] = 16'h3100;
        memory[49] = 16'h4200;
        memory[50] = 16'h9043;
        memory[51] = 16'h1000;
        memory[52] = 16'h3100;
        memory[53] = 16'h1876;
        memory[54] = 16'h4200;
        memory[55] = 16'h9089;
        memory[56] = 16'h1000;
        memory[57] = 16'h3100;
        memory[58] = 16'h1865;
        memory[59] = 16'h4200;
        memory[60] = 16'h90B6;
        memory[61] = 16'h1000;
        memory[62] = 16'h3100;
        memory[63] = 16'h1872;
        memory[64] = 16'h4200;
        memory[65] = 16'h90D3;
        memory[66] = 16'h80F1;
        memory[67] = 16'hA003;
        memory[68] = 16'h1865;
        memory[69] = 16'h4200;
        memory[70] = 16'h9048;
        memory[71] = 16'h80F1;
        memory[72] = 16'hA003;
        memory[73] = 16'h186C;
        memory[74] = 16'h4200;
        memory[75] = 16'h904D;
        memory[76] = 16'h80F1;
        memory[77] = 16'hA003;
        memory[78] = 16'h1870;
        memory[79] = 16'h4200;
        memory[80] = 16'h9052;
        memory[81] = 16'h80F1;
        memory[82] = 16'hA003;
        memory[83] = 16'h180A;
        memory[84] = 16'h4200;
        memory[85] = 16'h9057;
        memory[86] = 16'h80F1;
        memory[87] = 16'h1068;
        memory[88] = 16'hA001;
        memory[89] = 16'h1065;
        memory[90] = 16'hA001;
        memory[91] = 16'h106C;
        memory[92] = 16'hA001;
        memory[93] = 16'h1070;
        memory[94] = 16'hA001;
        memory[95] = 16'h1020;
        memory[96] = 16'hA001;
        memory[97] = 16'h1065;
        memory[98] = 16'hA001;
        memory[99] = 16'h1063;
        memory[100] = 16'hA001;
        memory[101] = 16'h1068;
        memory[102] = 16'hA001;
        memory[103] = 16'h106F;
        memory[104] = 16'hA001;
        memory[105] = 16'h1020;
        memory[106] = 16'hA001;
        memory[107] = 16'h1076;
        memory[108] = 16'hA001;
        memory[109] = 16'h1065;
        memory[110] = 16'hA001;
        memory[111] = 16'h1072;
        memory[112] = 16'hA001;
        memory[113] = 16'h1073;
        memory[114] = 16'hA001;
        memory[115] = 16'h1069;
        memory[116] = 16'hA001;
        memory[117] = 16'h106F;
        memory[118] = 16'hA001;
        memory[119] = 16'h106E;
        memory[120] = 16'hA001;
        memory[121] = 16'h1020;
        memory[122] = 16'hA001;
        memory[123] = 16'h1072;
        memory[124] = 16'hA001;
        memory[125] = 16'h1065;
        memory[126] = 16'hA001;
        memory[127] = 16'h1062;
        memory[128] = 16'hA001;
        memory[129] = 16'h106F;
        memory[130] = 16'hA001;
        memory[131] = 16'h106F;
        memory[132] = 16'hA001;
        memory[133] = 16'h1074;
        memory[134] = 16'hA001;
        memory[135] = 16'hA006;
        memory[136] = 16'h802A;
        memory[137] = 16'hA003;
        memory[138] = 16'h1865;
        memory[139] = 16'h4200;
        memory[140] = 16'h908E;
        memory[141] = 16'h80F1;
        memory[142] = 16'hA003;
        memory[143] = 16'h1872;
        memory[144] = 16'h4200;
        memory[145] = 16'h9093;
        memory[146] = 16'h80F1;
        memory[147] = 16'hA003;
        memory[148] = 16'h1873;
        memory[149] = 16'h4200;
        memory[150] = 16'h9098;
        memory[151] = 16'h80F1;
        memory[152] = 16'hA003;
        memory[153] = 16'h1869;
        memory[154] = 16'h4200;
        memory[155] = 16'h909D;
        memory[156] = 16'h80F1;
        memory[157] = 16'hA003;
        memory[158] = 16'h186F;
        memory[159] = 16'h4200;
        memory[160] = 16'h90A2;
        memory[161] = 16'h80F1;
        memory[162] = 16'hA003;
        memory[163] = 16'h186E;
        memory[164] = 16'h4200;
        memory[165] = 16'h90A7;
        memory[166] = 16'h80F1;
        memory[167] = 16'hA003;
        memory[168] = 16'h180A;
        memory[169] = 16'h4200;
        memory[170] = 16'h90AC;
        memory[171] = 16'h80F1;
        memory[172] = 16'h1076;
        memory[173] = 16'hA001;
        memory[174] = 16'h1030;
        memory[175] = 16'hA001;
        memory[176] = 16'h102E;
        memory[177] = 16'hA001;
        memory[178] = 16'h1031;
        memory[179] = 16'hA001;
        memory[180] = 16'hA006;
        memory[181] = 16'h802A;
        memory[182] = 16'hA003;
        memory[183] = 16'h1863;
        memory[184] = 16'h4200;
        memory[185] = 16'h90BB;
        memory[186] = 16'h80F1;
        memory[187] = 16'hA003;
        memory[188] = 16'h1868;
        memory[189] = 16'h4200;
        memory[190] = 16'h90C0;
        memory[191] = 16'h80F1;
        memory[192] = 16'hA003;
        memory[193] = 16'h186F;
        memory[194] = 16'h4200;
        memory[195] = 16'h90C5;
        memory[196] = 16'h80F1;
        memory[197] = 16'hA003;
        memory[198] = 16'h1C00;
        memory[199] = 16'h3C00;
        memory[200] = 16'h180A;
        memory[201] = 16'h1000;
        memory[202] = 16'h3300;
        memory[203] = 16'h4200;
        memory[204] = 16'h90D1;
        memory[205] = 16'h1000;
        memory[206] = 16'h3300;
        memory[207] = 16'hC000;
        memory[208] = 16'h80C5;
        memory[209] = 16'hA006;
        memory[210] = 16'h802A;
        memory[211] = 16'hA003;
        memory[212] = 16'h1865;
        memory[213] = 16'h4200;
        memory[214] = 16'h90D8;
        memory[215] = 16'h80F1;
        memory[216] = 16'hA003;
        memory[217] = 16'h1862;
        memory[218] = 16'h4200;
        memory[219] = 16'h90DD;
        memory[220] = 16'h80F1;
        memory[221] = 16'hA003;
        memory[222] = 16'h186F;
        memory[223] = 16'h4200;
        memory[224] = 16'h90E2;
        memory[225] = 16'h80F1;
        memory[226] = 16'hA003;
        memory[227] = 16'h186F;
        memory[228] = 16'h4200;
        memory[229] = 16'h90E7;
        memory[230] = 16'h80F1;
        memory[231] = 16'hA003;
        memory[232] = 16'h1874;
        memory[233] = 16'h4200;
        memory[234] = 16'h90EC;
        memory[235] = 16'h80F1;
        memory[236] = 16'hA003;
        memory[237] = 16'h180A;
        memory[238] = 16'h4200;
        memory[239] = 16'h900E;
        memory[240] = 16'h80F1;
        memory[241] = 16'h103F;
        memory[242] = 16'hA001;
        memory[243] = 16'hA006;
        memory[244] = 16'h802A;
    end

    always @(posedge clk) begin
        if (write_enable)
            memory[addr] <= data_in;
        data_out <= memory[addr];
    end

endmodule
