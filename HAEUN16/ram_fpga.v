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
        memory[0] = 16'h8046;
        memory[1] = 16'hC000;
        memory[2] = 16'hC001;
        memory[3] = 16'hB000;
        memory[4] = 16'hC000;
        memory[5] = 16'hB000;
        memory[6] = 16'hC001;
        memory[7] = 16'hB000;
        memory[8] = 16'hD000;
        memory[9] = 16'h9008;
        memory[10] = 16'h180D;
        memory[11] = 16'h1C00;
        memory[12] = 16'h3C00;
        memory[13] = 16'h4E00;
        memory[14] = 16'h9C10;
        memory[15] = 16'h8011;
        memory[16] = 16'h100A;
        memory[17] = 16'hA001;
        memory[18] = 16'hB000;
        memory[19] = 16'h100A;
        memory[20] = 16'hA001;
        memory[21] = 16'hB000;
        memory[22] = 16'h100A;
        memory[23] = 16'hA006;
        memory[24] = 16'hB000;
        memory[25] = 16'h100A;
        memory[26] = 16'hA004;
        memory[27] = 16'hB000;
        memory[28] = 16'h180A;
        memory[29] = 16'h4200;
        memory[30] = 16'h9023;
        memory[31] = 16'h180D;
        memory[32] = 16'h4200;
        memory[33] = 16'h9023;
        memory[34] = 16'h804C;
        memory[35] = 16'hB000;
        memory[36] = 16'h1030;
        memory[37] = 16'hC002;
        memory[38] = 16'h103E;
        memory[39] = 16'hA004;
        memory[40] = 16'h1020;
        memory[41] = 16'hA004;
        memory[42] = 16'h103E;
        memory[43] = 16'hA006;
        memory[44] = 16'h1020;
        memory[45] = 16'hA006;
        memory[46] = 16'hB000;
        memory[47] = 16'h1052;
        memory[48] = 16'h20F7;
        memory[49] = 16'h1045;
        memory[50] = 16'h20F8;
        memory[51] = 16'h1041;
        memory[52] = 16'h20F9;
        memory[53] = 16'h1044;
        memory[54] = 16'h20FA;
        memory[55] = 16'h1059;
        memory[56] = 16'h20FB;
        memory[57] = 16'h1000;
        memory[58] = 16'h20FC;
        memory[59] = 16'hB000;
        memory[60] = 16'h1000;
        memory[61] = 16'h1801;
        memory[62] = 16'h3200;
        memory[63] = 16'h1800;
        memory[64] = 16'h3800;
        memory[65] = 16'h1CF4;
        memory[66] = 16'h4B00;
        memory[67] = 16'h9845;
        memory[68] = 16'h803D;
        memory[69] = 16'hB000;
        memory[70] = 16'h1048;
        memory[71] = 16'hA004;
        memory[72] = 16'h1041;
        memory[73] = 16'hA004;
        memory[74] = 16'h1045;
        memory[75] = 16'hA004;
        memory[76] = 16'h1055;
        memory[77] = 16'hA004;
        memory[78] = 16'h104E;
        memory[79] = 16'hA004;
        memory[80] = 16'h102D;
        memory[81] = 16'hA004;
        memory[82] = 16'h104F;
        memory[83] = 16'hA004;
        memory[84] = 16'h1053;
        memory[85] = 16'hA004;
        memory[86] = 16'h1020;
        memory[87] = 16'hA004;
        memory[88] = 16'h1076;
        memory[89] = 16'hA004;
        memory[90] = 16'h1030;
        memory[91] = 16'hA004;
        memory[92] = 16'h102E;
        memory[93] = 16'hA004;
        memory[94] = 16'h1031;
        memory[95] = 16'hA004;
        memory[96] = 16'hA019;
        memory[97] = 16'h180C;
        memory[98] = 16'h100A;
        memory[99] = 16'hA006;
        memory[100] = 16'h1C01;
        memory[101] = 16'h4B00;
        memory[102] = 16'h9868;
        memory[103] = 16'h8062;
        memory[104] = 16'h1400;
        memory[105] = 16'h1020;
        memory[106] = 16'hA006;
        memory[107] = 16'h1801;
        memory[108] = 16'h3600;
        memory[109] = 16'h1800;
        memory[110] = 16'h3900;
        memory[111] = 16'h1C1E;
        memory[112] = 16'h4B00;
        memory[113] = 16'h9873;
        memory[114] = 16'h8069;
        memory[115] = 16'h1076;
        memory[116] = 16'hA006;
        memory[117] = 16'h1030;
        memory[118] = 16'hA006;
        memory[119] = 16'h102E;
        memory[120] = 16'hA006;
        memory[121] = 16'h1031;
        memory[122] = 16'hA006;
        memory[123] = 16'hA016;
        memory[124] = 16'hA02F;
        memory[125] = 16'h1401;
        memory[126] = 16'hA03C;
        memory[127] = 16'hA016;
        memory[128] = 16'h1030;
        memory[129] = 16'hC002;
        memory[130] = 16'hA024;
        memory[131] = 16'hA008;
        memory[132] = 16'h1400;
        memory[133] = 16'h3400;
        memory[134] = 16'h1868;
        memory[135] = 16'h1000;
        memory[136] = 16'h3100;
        memory[137] = 16'h4200;
        memory[138] = 16'h909B;
        memory[139] = 16'h1000;
        memory[140] = 16'h3100;
        memory[141] = 16'h1876;
        memory[142] = 16'h4200;
        memory[143] = 16'h90DE;
        memory[144] = 16'h1000;
        memory[145] = 16'h3100;
        memory[146] = 16'h1865;
        memory[147] = 16'h4200;
        memory[148] = 16'h9011;
        memory[149] = 16'h1000;
        memory[150] = 16'h3100;
        memory[151] = 16'h1872;
        memory[152] = 16'h4200;
        memory[153] = 16'h9030;
        memory[154] = 16'h804C;
        memory[155] = 16'hA008;
        memory[156] = 16'h1865;
        memory[157] = 16'h4200;
        memory[158] = 16'h90A0;
        memory[159] = 16'h804C;
        memory[160] = 16'hA008;
        memory[161] = 16'h186C;
        memory[162] = 16'h4200;
        memory[163] = 16'h90A5;
        memory[164] = 16'h804C;
        memory[165] = 16'hA008;
        memory[166] = 16'h1870;
        memory[167] = 16'h4200;
        memory[168] = 16'h90AA;
        memory[169] = 16'h804C;
        memory[170] = 16'hA008;
        memory[171] = 16'hA01C;
        memory[172] = 16'h1068;
        memory[173] = 16'hA004;
        memory[174] = 16'h1065;
        memory[175] = 16'hA004;
        memory[176] = 16'h106C;
        memory[177] = 16'hA004;
        memory[178] = 16'h1070;
        memory[179] = 16'hA004;
        memory[180] = 16'h1020;
        memory[181] = 16'hA004;
        memory[182] = 16'h1065;
        memory[183] = 16'hA004;
        memory[184] = 16'h1063;
        memory[185] = 16'hA004;
        memory[186] = 16'h1068;
        memory[187] = 16'hA004;
        memory[188] = 16'h106F;
        memory[189] = 16'hA004;
        memory[190] = 16'h1020;
        memory[191] = 16'hA004;
        memory[192] = 16'h1076;
        memory[193] = 16'hA004;
        memory[194] = 16'h1065;
        memory[195] = 16'hA004;
        memory[196] = 16'h1072;
        memory[197] = 16'hA004;
        memory[198] = 16'h1073;
        memory[199] = 16'hA004;
        memory[200] = 16'h1069;
        memory[201] = 16'hA004;
        memory[202] = 16'h106F;
        memory[203] = 16'hA004;
        memory[204] = 16'h106E;
        memory[205] = 16'hA004;
        memory[206] = 16'h1020;
        memory[207] = 16'hA004;
        memory[208] = 16'h1072;
        memory[209] = 16'hA004;
        memory[210] = 16'h1065;
        memory[211] = 16'hA004;
        memory[212] = 16'h1062;
        memory[213] = 16'hA004;
        memory[214] = 16'h106F;
        memory[215] = 16'hA004;
        memory[216] = 16'h106F;
        memory[217] = 16'hA004;
        memory[218] = 16'h1074;
        memory[219] = 16'hA004;
        memory[220] = 16'hA019;
        memory[221] = 16'h8082;
        memory[222] = 16'hA008;
        memory[223] = 16'h1865;
        memory[224] = 16'h4200;
        memory[225] = 16'h90E3;
        memory[226] = 16'h804C;
        memory[227] = 16'hA008;
        memory[228] = 16'h1872;
        memory[229] = 16'h4200;
        memory[230] = 16'h90E8;
        memory[231] = 16'h804C;
        memory[232] = 16'hA008;
        memory[233] = 16'h1873;
        memory[234] = 16'h4200;
        memory[235] = 16'h90ED;
        memory[236] = 16'h804C;
        memory[237] = 16'hA008;
        memory[238] = 16'h1869;
        memory[239] = 16'h4200;
        memory[240] = 16'h90F2;
        memory[241] = 16'h804C;
        memory[242] = 16'hA008;
        memory[243] = 16'h186F;
        memory[244] = 16'h4200;
        memory[245] = 16'h90F7;
        memory[246] = 16'h804C;
        memory[247] = 16'hA008;
        memory[248] = 16'h186E;
        memory[249] = 16'h4200;
        memory[250] = 16'h90FC;
        memory[251] = 16'h804C;
        memory[252] = 16'hA008;
        memory[253] = 16'hA01C;
        memory[254] = 16'h1076;
        memory[255] = 16'hA004;
        memory[256] = 16'h1030;
        memory[257] = 16'hA004;
        memory[258] = 16'h102E;
        memory[259] = 16'hA004;
        memory[260] = 16'h1031;
        memory[261] = 16'hA004;
        memory[262] = 16'hA019;
        memory[263] = 16'h1076;
        memory[264] = 16'hA006;
        memory[265] = 16'h1030;
        memory[266] = 16'hA006;
        memory[267] = 16'h102E;
        memory[268] = 16'hA006;
        memory[269] = 16'h1031;
        memory[270] = 16'hA006;
        memory[271] = 16'hA016;
        memory[272] = 16'h8082;
        memory[273] = 16'hA008;
        memory[274] = 16'h1863;
        memory[275] = 16'h4200;
        memory[276] = 16'h9016;
        memory[277] = 16'h804C;
        memory[278] = 16'hA008;
        memory[279] = 16'h1868;
        memory[280] = 16'h4200;
        memory[281] = 16'h901B;
        memory[282] = 16'h804C;
        memory[283] = 16'hA008;
        memory[284] = 16'h186F;
        memory[285] = 16'h4200;
        memory[286] = 16'h9020;
        memory[287] = 16'h804C;
        memory[288] = 16'hA008;
        memory[289] = 16'h1C00;
        memory[290] = 16'h3C00;
        memory[291] = 16'h180A;
        memory[292] = 16'h1000;
        memory[293] = 16'h3300;
        memory[294] = 16'h4200;
        memory[295] = 16'h902E;
        memory[296] = 16'h180D;
        memory[297] = 16'h1000;
        memory[298] = 16'h3300;
        memory[299] = 16'h4200;
        memory[300] = 16'h902E;
        memory[301] = 16'h8020;
        memory[302] = 16'hA013;
        memory[303] = 16'h8082;
        memory[304] = 16'hA008;
        memory[305] = 16'h1865;
        memory[306] = 16'h4200;
        memory[307] = 16'h9035;
        memory[308] = 16'h804C;
        memory[309] = 16'hA008;
        memory[310] = 16'h1862;
        memory[311] = 16'h4200;
        memory[312] = 16'h903A;
        memory[313] = 16'h804C;
        memory[314] = 16'hA008;
        memory[315] = 16'h186F;
        memory[316] = 16'h4200;
        memory[317] = 16'h903F;
        memory[318] = 16'h804C;
        memory[319] = 16'hA008;
        memory[320] = 16'h186F;
        memory[321] = 16'h4200;
        memory[322] = 16'h9044;
        memory[323] = 16'h804C;
        memory[324] = 16'hA008;
        memory[325] = 16'h1874;
        memory[326] = 16'h4200;
        memory[327] = 16'h9049;
        memory[328] = 16'h804C;
        memory[329] = 16'hA008;
        memory[330] = 16'hA01C;
        memory[331] = 16'h8046;
        memory[332] = 16'h103F;
        memory[333] = 16'hA004;
        memory[334] = 16'hA019;
        memory[335] = 16'h8082;
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
