/*
 * svo_bitmap_logo.v - PNG 비트맵 로고 오버레이 (1bpp ROM, 4-stage)
 * .gprj 에 등록하지 말 것 — svo_hdmi_soc.v 가 `include 함
 */
`ifndef SVO_BITMAP_LOGO_V
`define SVO_BITMAP_LOGO_V
`timescale 1ns / 1ps
`include "svo_defines.vh"

module svo_bitmap_logo #(
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

	wire pipeline_en;

	`include "svo_bitmap_logo_rom.vh"

	reg [7:0] rom_rdata;
	reg [LOGO_ROM_ABITS-1:0] rom_addr;

	always @(posedge oclk) begin
		if (pipeline_en)
			rom_rdata <= logo_rom_flat[rom_addr * 8 +: 8];
	end

	reg [3:0] oresetn_q;
	reg oresetn;

	always @(posedge oclk)
		{oresetn, oresetn_q} <= {oresetn_q, resetn};

	// stage 1: scan position
	reg p1_start_of_frame;
	reg p1_valid;
	reg [`SVO_XYBITS-1:0] p1_xpos, p1_ypos;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p1_xpos <= 0;
			p1_ypos <= 0;
			p1_valid <= 0;
		end else if (pipeline_en) begin
			p1_valid <= 1'b1;
			p1_start_of_frame <= !p1_xpos && !p1_ypos;
			if (p1_xpos == SVO_HOR_PIXELS - 1) begin
				p1_xpos <= 0;
				p1_ypos <= p1_ypos == SVO_VER_PIXELS - 1 ? 0 : p1_ypos + 1;
			end else begin
				p1_xpos <= p1_xpos + 1;
			end
		end
	end

	wire [`SVO_XYBITS-1:0] p1_lx = p1_xpos - LOGO_X0;
	wire [`SVO_XYBITS-1:0] p1_ly = p1_ypos - LOGO_Y0;
	wire p1_in_box = (p1_xpos >= LOGO_X0) && (p1_xpos < LOGO_X0 + LOGO_W) &&
	                 (p1_ypos >= LOGO_Y0) && (p1_ypos < LOGO_Y0 + LOGO_H);
	wire [LOGO_ROM_ABITS-1:0] p1_rom_addr =
		(p1_ly * LOGO_ROW_BYTES) + (p1_lx >> 3);

	// stage 2: ROM address (in_box 밖이면 addr=0)
	reg p2_valid;
	reg p2_start_of_frame;
	reg p2_in_box;
	reg [2:0] p2_lx;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p2_valid <= 0;
		end else if (pipeline_en) begin
			p2_valid <= p1_valid;
			p2_start_of_frame <= p1_start_of_frame;
			p2_in_box <= p1_in_box;
			p2_lx <= p1_lx[2:0];
			rom_addr <= p1_in_box ? p1_rom_addr : {LOGO_ROM_ABITS{1'b0}};
		end
	end

	// stage 3: ROM data registered — in_box/lx 동기 지연
	reg p3_valid;
	reg p3_start_of_frame;
	reg p3_in_box;
	reg [2:0] p3_lx;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p3_valid <= 0;
		end else if (pipeline_en) begin
			p3_valid <= p2_valid;
			p3_start_of_frame <= p2_start_of_frame;
			p3_in_box <= p2_in_box;
			p3_lx <= p2_lx;
		end
	end

	// stage 4: bit extract (rom_rdata ↔ addr 1클럭 정렬)
	reg p4_valid;
	reg p4_start_of_frame;
	reg p4_fg;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p4_valid <= 0;
		end else if (pipeline_en) begin
			p4_valid <= p3_valid;
			p4_start_of_frame <= p3_start_of_frame;
			p4_fg <= p3_in_box && rom_rdata[7 - p3_lx];
		end
	end

	assign pipeline_en = !p4_valid || out_axis_tready;

	assign out_axis_tvalid = p4_valid;
	assign out_axis_tdata  = p4_fg ? 2'b10 : 2'b00;
	assign out_axis_tuser  = p4_start_of_frame;

endmodule
`endif
