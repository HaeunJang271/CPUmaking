// ============================================================================
// cpu.v - HAEUN-16 16비트 CPU (통합)
// ============================================================================
// 구성: ALU, PC, 레지스터 파일(R0~R3), RAM, 명령 디코더, 제어 유닛
// 실행 흐름: Fetch1 -> Fetch2 -> Execute/Writeback (STORE/CALL/RET 추가 사이클)
// ISA: ISA.md (v1 + v2: JZ, CALL, RET, OUT, IN)
// 합성: Verilog-2001
// ============================================================================

module cpu (
    input  wire        clk,           // 시스템 클럭
    input  wire        reset,         // 동기 리셋
    output wire [15:0] r0,            // 레지스터 R0 (디버그/테스트용)
    output wire [15:0] r1,            // 레지스터 R1
    output wire [15:0] r2,            // 레지스터 R2
    output wire [15:0] r3,            // 레지스터 R3
    output wire [15:0] pc_out,        // 현재 PC
    output wire        io_out_strobe, // OUT 명령 1사이클 펄스
    output wire [7:0]  io_out_port,   // OUT 포트 번호 (0 = UART TX)
    output wire [7:0]  io_out_data,   // OUT 데이터 (하위 8비트)
    output wire        io_in_strobe,  // IN 명령 1사이클 펄스
    output wire [7:0]  io_in_port,    // IN 포트 번호 (0 = UART RX)
    input  wire [7:0]  io_in_data,   // IN 포트 데이터 (시뮬/FPGA)
    // STORE imm8 0x80..0xBF -> HDMI screen_ram (SCREEN0 = 0x80)
    output wire        screen_wr,
    output wire [5:0]  screen_addr,
    output wire [7:0]  screen_data,
    input  wire        peek_clk,
    input  wire [7:0]  peek_addr,
    output wire [15:0] peek_data
);

    // -------------------------------------------------------------------------
    // FSM 상태
    // -------------------------------------------------------------------------
    localparam [2:0] ST_FETCH1 = 3'd0;
    localparam [2:0] ST_FETCH2 = 3'd1;
    localparam [2:0] ST_EXEC   = 3'd2;
    localparam [2:0] ST_STORE  = 3'd3;
    localparam [2:0] ST_CALL   = 3'd4;
    localparam [2:0] ST_RET    = 3'd5;
    localparam [2:0] ST_RET2   = 3'd6;
    localparam [2:0] ST_RET3   = 3'd7;

    reg [2:0] state;
    reg [15:0] ir;

    // CALL/RET 스택 포인터 (word 주소, 255=비어있음)
    reg [7:0] sp;

    // -------------------------------------------------------------------------
    // 명령어 필드 (Decode)
    // -------------------------------------------------------------------------
    wire [3:0] opcode = ir[15:12];
    wire [1:0] rd     = ir[11:10];
    wire [1:0] rs     = ir[9:8];
    wire [7:0] imm8   = ir[7:0];

    wire is_nop   = (opcode == 4'b0000);
    wire is_load  = (opcode == 4'b0001);
    wire is_store = (opcode == 4'b0010);
    wire is_add   = (opcode == 4'b0011);
    wire is_sub   = (opcode == 4'b0100);
    wire is_and   = (opcode == 4'b0101);
    wire is_or    = (opcode == 4'b0110);
    wire is_xor   = (opcode == 4'b0111);
    wire is_jmp   = (opcode == 4'b1000);
    wire is_jz    = (opcode == 4'b1001);
    wire is_call  = (opcode == 4'b1010);
    wire is_ret   = (opcode == 4'b1011);
    wire is_out   = (opcode == 4'b1100);
    wire is_in    = (opcode == 4'b1101);

    wire is_alu = is_add | is_sub | is_and | is_or | is_xor;
    wire reg_write = (state == ST_EXEC) && (is_load | is_alu | is_in);

    reg [2:0] alu_op;
    always @(*) begin
        case (opcode)
            4'b0011: alu_op = 3'b000;
            4'b0100: alu_op = 3'b001;
            4'b0101: alu_op = 3'b010;
            4'b0110: alu_op = 3'b011;
            4'b0111: alu_op = 3'b100;
            default: alu_op = 3'b000;
        endcase
    end

    // -------------------------------------------------------------------------
    // 레지스터 파일 (R0~R3)
    // -------------------------------------------------------------------------
    wire [15:0] rf_out [0:3];
    wire [15:0] wb_data;
    wire        load_r0;
    wire        load_r1;
    wire        load_r2;
    wire        load_r3;

    assign load_r0 = reg_write && (rd == 2'b00);
    assign load_r1 = reg_write && (rd == 2'b01);
    assign load_r2 = reg_write && (rd == 2'b10);
    assign load_r3 = reg_write && (rd == 2'b11);

    register16 u_r0 (
        .clk(clk), .reset(reset), .load(load_r0),
        .data_in(wb_data), .data_out(rf_out[0])
    );
    register16 u_r1 (
        .clk(clk), .reset(reset), .load(load_r1),
        .data_in(wb_data), .data_out(rf_out[1])
    );
    register16 u_r2 (
        .clk(clk), .reset(reset), .load(load_r2),
        .data_in(wb_data), .data_out(rf_out[2])
    );
    register16 u_r3 (
        .clk(clk), .reset(reset), .load(load_r3),
        .data_in(wb_data), .data_out(rf_out[3])
    );

    assign r0 = rf_out[0];
    assign r1 = rf_out[1];
    assign r2 = rf_out[2];
    assign r3 = rf_out[3];

    // 레지스터 읽기 (JZ/CALL 등에서 Rd/Rs 사용)
    wire [15:0] rs_val = (rs == 2'b00) ? rf_out[0] :
                         (rs == 2'b01) ? rf_out[1] :
                         (rs == 2'b10) ? rf_out[2] :
                         (rs == 2'b11) ? rf_out[3] : 16'h0000;

    wire [15:0] rd_val = (rd == 2'b00) ? rf_out[0] :
                         (rd == 2'b01) ? rf_out[1] :
                         (rd == 2'b10) ? rf_out[2] :
                         (rd == 2'b11) ? rf_out[3] : 16'h0000;
    wire        rd_zero = (rd_val == 16'h0000);

    assign wb_data = is_load ? {8'b0, imm8} :
                       is_in  ? {8'b0, io_in_data} :
                                alu_result;

    // -------------------------------------------------------------------------
    // ALU
    // -------------------------------------------------------------------------
    wire [15:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .A      (rd_val),
        .B      (rs_val),
        .ALU_OP (alu_op),
        .RESULT (alu_result),
        .ZERO   (alu_zero)
    );

    // -------------------------------------------------------------------------
    // Program Counter
    // -------------------------------------------------------------------------
    wire pc_enable;
    wire pc_jump;
    wire [15:0] jump_addr;

    wire jz_take = is_jz && rd_zero;

    assign pc_enable = (state == ST_EXEC) &&
                       !is_jmp && !jz_take && !is_call && !is_ret;
    assign pc_jump   = ((state == ST_EXEC) && (is_jmp || jz_take)) ||
                       (state == ST_CALL) ||
                       (state == ST_RET3);
    assign jump_addr = (state == ST_RET3) ? mem_rdata :
                       {8'b0, imm8};

    pc u_pc (
        .clk       (clk),
        .reset     (reset),
        .enable    (pc_enable),
        .jump      (pc_jump),
        .jump_addr (jump_addr),
        .pc_out    (pc_out)
    );

    // -------------------------------------------------------------------------
    // RAM 인터페이스
    // -------------------------------------------------------------------------
    wire [15:0] mem_rdata;
    wire [15:0] mem_wdata;
    wire [15:0] mem_addr;
    wire        mem_we;

    wire [15:0] ret_addr = pc_out + 16'd1;

    wire screen_store = (state == ST_STORE) &&
                        (imm8 >= 8'h80) && (imm8 <= 8'hBF);

    assign mem_wdata = (state == ST_CALL) ? ret_addr : rs_val;
    assign mem_addr  = (state == ST_STORE) ? {8'b0, imm8} :
                       (state == ST_CALL)  ? {8'b0, sp} :
                       (state == ST_RET2 || state == ST_RET3) ? {8'b0, sp} :
                       pc_out;
    assign mem_we    = ((state == ST_STORE) && !screen_store) || (state == ST_CALL);

    assign screen_wr    = screen_store;
    assign screen_addr  = imm8[5:0];
    assign screen_data  = rs_val[7:0];

    ram_fpga u_ram (
        .clk          (clk),
        .write_enable (mem_we),
        .address      (mem_addr),
        .data_in      (mem_wdata),
        .data_out     (mem_rdata),
        .peek_clk     (peek_clk),
        .peek_addr    (peek_addr),
        .peek_data    (peek_data)
    );

    // -------------------------------------------------------------------------
    // I/O (OUT 명령)
    // -------------------------------------------------------------------------
    assign io_out_strobe = (state == ST_EXEC) && is_out;
    assign io_out_port   = imm8;
    assign io_out_data   = rs_val[7:0];
    assign io_in_strobe  = (state == ST_EXEC) && is_in;
    assign io_in_port    = imm8;

    // -------------------------------------------------------------------------
    // 제어 유닛 FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_FETCH1;
            ir    <= 16'h0000;
            sp    <= 8'd255;
        end else begin
            case (state)
                ST_FETCH1: state <= ST_FETCH2;

                ST_FETCH2: begin
                    ir    <= mem_rdata;
                    state <= ST_EXEC;
                end

                ST_EXEC: begin
                    if (is_store)
                        state <= ST_STORE;
                    else if (is_call)
                        state <= ST_CALL;
                    else if (is_ret)
                        state <= ST_RET;
                    else
                        state <= ST_FETCH1;
                end

                ST_STORE: state <= ST_FETCH1;

                // CALL: RAM[sp] <- PC+1, sp--, PC <- imm8
                ST_CALL: begin
                    if (sp != 8'd0)
                        sp <= sp - 8'd1;
                    state <= ST_FETCH1;
                end

                // RET: sp++, RAM[sp] 읽어 PC 복귀 (2사이클 read)
                ST_RET: begin
                    if (sp != 8'd255)
                        sp <= sp + 8'd1;
                    state <= ST_RET2;
                end

                ST_RET2: state <= ST_RET3;

                ST_RET3: state <= ST_FETCH1;

                default: state <= ST_FETCH1;
            endcase
        end
    end

endmodule
