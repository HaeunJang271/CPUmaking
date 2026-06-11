// ============================================================================
// svo_term_inject.v - 부팅 시 고정 문자열을 svo_term 에 주입
// ============================================================================

module svo_term_inject (
    input  wire       clk,
    input  wire       resetn,
    output reg        out_axis_tvalid,
    input  wire       out_axis_tready,
    output reg [7:0]  out_axis_tdata
);
    localparam MSG_LEN = 6'd35;

    reg [5:0] idx;

    function [7:0] msg_char;
        input [5:0] i;
        begin
            case (i)
                6'd0:  msg_char = "H";
                6'd1:  msg_char = "A";
                6'd2:  msg_char = "E";
                6'd3:  msg_char = "U";
                6'd4:  msg_char = "N";
                6'd5:  msg_char = "-";
                6'd6:  msg_char = "1";
                6'd7:  msg_char = "6";
                6'd8:  msg_char = "\n";
                6'd9:  msg_char = "H";
                6'd10: msg_char = "D";
                6'd11: msg_char = "M";
                6'd12: msg_char = "I";
                6'd13: msg_char = " ";
                6'd14: msg_char = "t";
                6'd15: msg_char = "e";
                6'd16: msg_char = "x";
                6'd17: msg_char = "t";
                6'd18: msg_char = " ";
                6'd19: msg_char = "O";
                6'd20: msg_char = "K";
                6'd21: msg_char = "\n";
                6'd22: msg_char = "6";
                6'd23: msg_char = "4";
                6'd24: msg_char = "0";
                6'd25: msg_char = "x";
                6'd26: msg_char = "4";
                6'd27: msg_char = "8";
                6'd28: msg_char = "0";
                6'd29: msg_char = " ";
                6'd30: msg_char = "@";
                6'd31: msg_char = "6";
                6'd32: msg_char = "0";
                6'd33: msg_char = "\n";
                6'd34: msg_char = "\n";
                default: msg_char = 8'h00;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            idx            <= 6'd0;
            out_axis_tvalid <= 1'b0;
            out_axis_tdata  <= 8'h00;
        end else if (idx < MSG_LEN) begin
            out_axis_tvalid <= 1'b1;
            out_axis_tdata  <= msg_char(idx);
            if (out_axis_tvalid && out_axis_tready)
                idx <= idx + 6'd1;
        end else begin
            out_axis_tvalid <= 1'b0;
        end
    end

endmodule
