// ============================================================================
// screen_status.v - CPU 레지스터/PC를 HDMI 텍스트 버퍼에 16진 덤프
// ============================================================================
// 출력 형식 (4줄):
//   HAEUN-16
//   R0:XXXX
//   R1:XXXX
//   PC:XXXX
// ============================================================================

module screen_status (
    input  wire       clk,
    input  wire       resetn,
    input  wire       enable,
    input  wire [15:0] r0,
    input  wire [15:0] r1,
    input  wire [15:0] pc,
    output reg        wr_en,
    output reg  [5:0] wr_addr,
    output reg  [7:0] wr_data
);
    localparam MSG_LEN          = 6'd33;
    localparam CLK_PER_FRAME    = 19'd416667;
    localparam FRAMES_PER_UPDATE = 4'd30;

    function [7:0] hex_char;
        input [3:0] nibble;
        begin
            hex_char = (nibble < 4'd10) ? (8'h30 + nibble) : (8'h37 + nibble);
        end
    endfunction

    reg [18:0] frame_cnt;
    reg [3:0]  frame_div;
    reg        busy;
    reg        boot_pending;
    reg [5:0]  byte_idx;
    reg [15:0] r0_cap;
    reg [15:0] r1_cap;
    reg [15:0] pc_cap;

    always @(posedge clk) begin
        if (!resetn) begin
            frame_cnt    <= 19'd0;
            frame_div    <= 4'd0;
            busy         <= 1'b0;
            boot_pending <= 1'b1;
            byte_idx     <= 6'd0;
            wr_en        <= 1'b0;
        end else begin
            wr_en <= 1'b0;

            if (!enable) begin
                busy <= 1'b0;
            end else if (!busy) begin
                if (boot_pending) begin
                    boot_pending <= 1'b0;
                    r0_cap       <= r0;
                    r1_cap       <= r1;
                    pc_cap       <= pc;
                    busy         <= 1'b1;
                    byte_idx     <= 6'd0;
                end else if (frame_cnt >= CLK_PER_FRAME) begin
                    frame_cnt <= 19'd0;
                    if (frame_div >= FRAMES_PER_UPDATE - 1) begin
                        frame_div <= 4'd0;
                        r0_cap    <= r0;
                        r1_cap    <= r1;
                        pc_cap    <= pc;
                        busy      <= 1'b1;
                        byte_idx  <= 6'd0;
                    end else begin
                        frame_div <= frame_div + 4'd1;
                    end
                end else begin
                    frame_cnt <= frame_cnt + 19'd1;
                end
            end else begin
                wr_en   <= 1'b1;
                wr_addr <= byte_idx;
                case (byte_idx)
                    6'd0:  wr_data <= "H";
                    6'd1:  wr_data <= "A";
                    6'd2:  wr_data <= "E";
                    6'd3:  wr_data <= "U";
                    6'd4:  wr_data <= "N";
                    6'd5:  wr_data <= "-";
                    6'd6:  wr_data <= "1";
                    6'd7:  wr_data <= "6";
                    6'd8:  wr_data <= "\n";
                    6'd9:  wr_data <= "R";
                    6'd10: wr_data <= "0";
                    6'd11: wr_data <= ":";
                    6'd12: wr_data <= hex_char(r0_cap[15:12]);
                    6'd13: wr_data <= hex_char(r0_cap[11:8]);
                    6'd14: wr_data <= hex_char(r0_cap[7:4]);
                    6'd15: wr_data <= hex_char(r0_cap[3:0]);
                    6'd16: wr_data <= "\n";
                    6'd17: wr_data <= "R";
                    6'd18: wr_data <= "1";
                    6'd19: wr_data <= ":";
                    6'd20: wr_data <= hex_char(r1_cap[15:12]);
                    6'd21: wr_data <= hex_char(r1_cap[11:8]);
                    6'd22: wr_data <= hex_char(r1_cap[7:4]);
                    6'd23: wr_data <= hex_char(r1_cap[3:0]);
                    6'd24: wr_data <= "\n";
                    6'd25: wr_data <= "P";
                    6'd26: wr_data <= "C";
                    6'd27: wr_data <= ":";
                    6'd28: wr_data <= hex_char(pc_cap[15:12]);
                    6'd29: wr_data <= hex_char(pc_cap[11:8]);
                    6'd30: wr_data <= hex_char(pc_cap[7:4]);
                    6'd31: wr_data <= hex_char(pc_cap[3:0]);
                    6'd32: wr_data <= "\n";
                    default: wr_data <= 8'h00;
                endcase

                if (byte_idx + 1 >= MSG_LEN) begin
                    busy <= 1'b0;
                end else begin
                    byte_idx <= byte_idx + 6'd1;
                end
            end
        end
    end
endmodule
