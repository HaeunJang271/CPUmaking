// ============================================================================
// cpu.v - HAEUN-16 16비트 CPU (통합)
// ============================================================================
// 구성: ALU, PC, 레지스터 파일(R0~R3), RAM, 명령 디코더, 제어 유닛
// 실행 흐름: Fetch1 -> Fetch2 -> Execute/Writeback (STORE는 추가 사이클)
// ISA: ISA.md 참조
// 합성: Verilog-2001
// ============================================================================

module cpu (
    input  wire        clk,       // 시스템 클럭
    input  wire        reset,     // 동기 리셋
    output wire [15:0] r0,        // 레지스터 R0 (디버그/테스트용)
    output wire [15:0] r1,        // 레지스터 R1
    output wire [15:0] r2,        // 레지스터 R2
    output wire [15:0] r3,        // 레지스터 R3
    output wire [15:0] pc_out     // 현재 PC
);

    // -------------------------------------------------------------------------
    // FSM 상태 (동기 RAM 읽기 2사이클 Fetch)
    // -------------------------------------------------------------------------
    localparam [1:0] ST_FETCH1 = 2'd0;  // PC 주소로 RAM 읽기 시작
    localparam [1:0] ST_FETCH2 = 2'd1;  // 읽은 명령어를 ir에 래치
    localparam [1:0] ST_EXEC   = 2'd2;  // Decode / Execute / Writeback
    localparam [1:0] ST_STORE  = 2'd3;  // STORE RAM 쓰기

    reg [1:0] state;
    reg [15:0] ir;                    // 명령어 레지스터

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

    wire is_alu = is_add | is_sub | is_and | is_or | is_xor;
    // Writeback은 Execute 사이클에서만 수행
    wire reg_write = (state == ST_EXEC) && (is_load | is_alu);

    // ALU_OP 매핑 (opcode 0011~0111 -> ALU 000~100)
    reg [2:0] alu_op;
    always @(*) begin
        case (opcode)
            4'b0011: alu_op = 3'b000; // ADD
            4'b0100: alu_op = 3'b001; // SUB
            4'b0101: alu_op = 3'b010; // AND
            4'b0110: alu_op = 3'b011; // OR
            4'b0111: alu_op = 3'b100; // XOR
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

    function [15:0] read_reg;
        input [1:0] sel;
        begin
            case (sel)
                2'b00: read_reg = rf_out[0];
                2'b01: read_reg = rf_out[1];
                2'b10: read_reg = rf_out[2];
                2'b11: read_reg = rf_out[3];
                default: read_reg = 16'h0000;
            endcase
        end
    endfunction

    wire [15:0] rs_val = read_reg(rs);
    wire [15:0] rd_val = read_reg(rd);

    assign wb_data = is_load ? {8'b0, imm8} : alu_result;

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

    assign pc_enable = (state == ST_EXEC) && !is_jmp;
    assign pc_jump   = (state == ST_EXEC) && is_jmp;
    assign jump_addr = {8'b0, imm8};

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

    assign mem_wdata = rs_val;
    assign mem_addr  = (state == ST_STORE) ? {8'b0, imm8} : pc_out;
    assign mem_we    = (state == ST_STORE);

    ram u_ram (
        .clk          (clk),
        .write_enable (mem_we),
        .address      (mem_addr),
        .data_in      (mem_wdata),
        .data_out     (mem_rdata)
    );

    // -------------------------------------------------------------------------
    // 제어 유닛 FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_FETCH1;
            ir    <= 16'h0000;
        end else begin
            case (state)
                // Fetch1: mem_addr=pc_out, RAM 읽기 1사이클 대기
                ST_FETCH1: begin
                    state <= ST_FETCH2;
                end

                // Fetch2: 명령어 래치 후 실행 단계로
                ST_FETCH2: begin
                    ir    <= mem_rdata;
                    state <= ST_EXEC;
                end

                // Execute: 레지스터 쓰기(PC 갱신은 pc 모듈이 처리)
                ST_EXEC: begin
                    if (is_store)
                        state <= ST_STORE;
                    else
                        state <= ST_FETCH1;
                end

                // Store: RAM[imm8] <- Rs
                ST_STORE: begin
                    state <= ST_FETCH1;
                end

                default: state <= ST_FETCH1;
            endcase
        end
    end

endmodule
