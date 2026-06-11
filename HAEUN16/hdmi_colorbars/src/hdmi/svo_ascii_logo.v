/*
 * svo_ascii_logo.v - HAEUN-OS /|\ ASCII 로고 (2x 스케일)
 */
`timescale 1ns / 1ps
`include "svo_defines.vh"

module svo_ascii_logo #(
	`SVO_DEFAULT_PARAMS
) (
	input oclk,
	input resetn,
	output       out_axis_tvalid,
	input        out_axis_tready,
	output [1:0] out_axis_tdata,
	output [0:0] out_axis_tuser
);
	`SVO_DECLS

	localparam [3:0] PX_PER_CELL = 4'd15; // 16px = 8x8 font x2
	localparam [9:0] LOGO_X0 = 10'd48;    // (640 - 34*16) / 2

	wire pipeline_en;

	reg [MEM_ABITS-1:0] mem_portB_addr;
	reg [7:0] mem_portB_rdata;
	reg [MEM_ABITS-1:0] mem_stop_B;

	`include "svo_ascii_logo_rom.vh"
	`include "svo_font_8x8.vh"

	always @(posedge oclk) begin
		if (pipeline_en)
			mem_portB_rdata <= (mem_portB_addr < MSG_STOP) ? msg_rom[mem_portB_addr] : 8'h00;
		mem_stop_B <= MSG_STOP;
	end

	reg [3:0] oresetn_q;
	reg oresetn;

	always @(posedge oclk)
		{oresetn, oresetn_q} <= {oresetn_q, resetn};

	reg p1_start_of_frame;
	reg p1_start_of_line;
	reg p1_valid;
	reg [`SVO_XYBITS-1:0] p1_xpos, p1_ypos;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p1_xpos  <= 0;
			p1_ypos  <= 0;
			p1_valid <= 0;
		end else if (pipeline_en) begin
			p1_valid <= 1'b1;
			p1_start_of_frame <= !p1_xpos && !p1_ypos;
			p1_start_of_line <= !p1_xpos;
			if (p1_xpos == SVO_HOR_PIXELS - 1) begin
				p1_xpos <= 0;
				p1_ypos <= p1_ypos == SVO_VER_PIXELS - 1 ? 0 : p1_ypos + 1;
			end else begin
				p1_xpos <= p1_xpos + 1;
			end
		end
	end

	reg [3:0] p2_x, p2_y;
	reg p2_start_of_frame;
	reg p2_start_of_line;
	reg p2_valid;
	reg p2_found_end;
	reg [MEM_ABITS-1:0] p2_line_start_addr;
	wire [MEM_ABITS-1:0] next_mem_portB_addr;

	assign next_mem_portB_addr = (mem_portB_addr + 1 >= MSG_STOP) ? MSG_STOP : mem_portB_addr + 1;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p2_valid <= 0;
			p2_found_end <= 1'b1;
		end else if (pipeline_en) begin
			p2_start_of_frame <= p1_start_of_frame;
			p2_start_of_line <= p1_start_of_line;
			p2_valid <= p1_valid;

			if (mem_portB_addr == mem_stop_B)
				p2_found_end <= 1'b1;

			if (p1_start_of_frame) begin
				mem_portB_addr <= 0;
				p2_line_start_addr <= 0;
				p2_found_end <= 0;
				p2_x <= 0;
				p2_y <= 0;
			end else if (p1_start_of_line) begin
				if (p2_y == PX_PER_CELL) begin
					if (mem_portB_addr != mem_stop_B) begin
						mem_portB_addr <= next_mem_portB_addr;
						p2_line_start_addr <= next_mem_portB_addr;
					end else begin
						p2_line_start_addr <= mem_stop_B;
					end
				end else begin
					mem_portB_addr <= p2_line_start_addr;
				end
				p2_x <= 0;
				p2_y <= p2_y + 4'd1;
			end else begin
				if (p2_x == PX_PER_CELL) begin
					if (mem_portB_addr != mem_stop_B && mem_portB_rdata != 8'd10)
						mem_portB_addr <= next_mem_portB_addr;
				end
				p2_x <= p2_x + 4'd1;
			end
		end
	end

	reg [3:0] p3_x, p3_y;
	reg p3_start_of_frame;
	reg p3_valid;
	reg [`SVO_XYBITS-1:0] p3_xpos, p3_ypos;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p3_valid <= 0;
		end else if (pipeline_en) begin
			p3_x <= p2_x;
			p3_y <= p2_y;
			p3_xpos <= p1_xpos;
			p3_ypos <= p1_ypos;
			p3_start_of_frame <= p2_start_of_frame;
			p3_valid <= p2_valid;
		end
	end

	reg [7:0] p4_c;
	reg [2:0] p4_fx, p4_fy;
	reg p4_start_of_frame;
	reg p4_valid;
	reg p4_in_box;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p4_valid <= 0;
		end else if (pipeline_en) begin
			p4_c <= mem_portB_rdata;
			p4_fx <= p3_x[3:1];
			p4_fy <= p3_y[3:1];
			p4_in_box <= (p3_xpos >= LOGO_X0) &&
			             (p3_xpos < LOGO_X0 + (LOGO_COLS * 16)) &&
			             (p3_ypos < (LOGO_ROWS * 16));
			p4_start_of_frame <= p3_start_of_frame;
			p4_valid <= p3_valid;
		end
	end

	reg [1:0] p5_outval;
	reg p5_start_of_frame;
	reg p5_valid;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p5_valid <= 0;
		end else if (pipeline_en) begin
			if (p4_in_box && 32 <= p4_c && p4_c < 128)
				p5_outval <= font(p4_c, p4_fx, p4_fy) ? 2'b10 : 2'b00;
			else
				p5_outval <= 2'b00;
			p5_start_of_frame <= p4_start_of_frame;
			p5_valid <= p4_valid;
		end
	end

	assign pipeline_en = !p5_valid || out_axis_tready;

	assign out_axis_tvalid = p5_valid;
	assign out_axis_tdata  = p5_outval;
	assign out_axis_tuser  = p5_start_of_frame;

endmodule
