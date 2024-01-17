// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Author: Ahmed Abdelazeem
// Github: https://github.com/abdelazeem201
// Email: ahmed_abdelazeem@outlook.com
// Description: VID_TIMING_GEN
// Dependencies: 
// Since: 2021-12-24 15:16:50
// LastEditors: Ahmed Abdelazeem
// LastEditTime: 2024-01-17 15:16:50
// ********************************************************************
// Module Function
`timescale 1 ps/1 ps

module dlp_top (
	input			clk,
	input			rst_n,
	
	// external ddr2 port
	output  [15:0] 	mem_addr,
	output  [2:0] 	mem_ba,
	output          mem_cas_n,
	output  		mem_cke,
	inout   		mem_clk,
	inout   		mem_clk_n,
	output  		mem_cs_n,
	output	[1:0] 	mem_dm,
	inout   [15:0] 	mem_dq,
	inout   [1:0] 	mem_dqs,
	output  [0:0] 	mem_odt,
	output          mem_ras_n,
	output          mem_we_n
);

	// Video signal control
	wire 			ctrl_ven=1;    	// video enable signal
	wire      ctrl_hsync_pol=0; // horizontal sync pulse polarization level (pos/neg)
	wire      ctrl_vsync_pol=0; // vertical sync pulse polarization level (pos/neg)
	wire 			ctrl_blank_pol=0; // blank signal polarization level
	wire 			ctrl_daten_pol=0; // data enable signal polarization level

	// horiontal timing settings
	wire 	[ 7:0] 	Thsync=8; // horizontal sync pulse width (in pixels)
	wire 	[ 7:0] 	Thgdel=12;	// horizontal gate delay (in pixels)
	wire 	[15:0] 	Thgate=100; // horizontal gate length (number of visible pixels per line)
	wire 	[15:0] 	Thlen=130;  // horizontal length (number of pixels per line)

	// vertical timing settings
	wire 	[ 7:0] 	Tvsync=1; // vertical sync pulse width (in lines)
	wire 	[ 7:0] 	Tvgdel=2; // vertical gate delay (in lines)
	wire 	[15:0] 	Tvgate=16; // vertical gate length (number of visible lines in frame)
	wire 	[15:0] 	Tvlen=22;  // vertical length (number of lines in frame)

	// status wires
	wire 			eoh; // end of horizontal
	wire 			eov; // end of vertical
	
	wire			load_ready;
	wire	[23:0]	load_data;
	wire			load_valid;

	// pixel related wires
	wire 			pclk;	// pixel clock out
	wire 			hsync; // horizontal sync pulse
	wire 			vsync; // vertical sync pulse
	wire 			blank; // blanking signal
	wire 			daten;
	wire 	[23:0] 	pdata;
	
	wire 	[31:0] 	shift_taps;
	
	// data from host to ddr2
	wire    		local_wr_req;
	wire	[23:0]	local_wr_data;
	wire			local_wr_valid;
	wire			local_wr_ready;
	// load data from ddr2
	wire			local_rd_req;
	wire			local_rd_ready;
	wire	[23:0]	local_rd_data;
	wire			local_rd_valid;
	

	// video pixel generator module
	video_pixel_gen INST_VIDEO (
		.clk	 		(clk),
		.rst_n 	 		(rst_n),
		.ctrl_ven 		(ctrl_ven),
		.ctrl_hsync_pol	(ctrl_hsync_pol),
		.ctrl_vsync_pol	(ctrl_vsync_pol),
		.ctrl_blank_pol	(ctrl_blank_pol),
		.ctrl_daten_pol	(ctrl_daten_pol),
		.Thsync  		(Thsync),
		.Thgdel  		(Thgdel),
		.Thgate  		(Thgate),
		.Thlen   		(Thlen),
		.Tvsync  		(Tvsync),
		.Tvgdel  		(Tvgdel),
		.Tvgate  		(Tvgate),
		.Tvlen   		(Tvlen),
		.eoh     		(eoh),
		.eov     		(eov),
		.load_ready		(load_ready),
		.load_data		(load_data),
		.load_valid		(load_valid),
		.pclk    		(pclk),
		.hsync   		(hsync),
		.vsync   		(vsync),
		.blank   		(blank),
		.daten			(daten),
		.pdata			(pdata)
	);
	
	// shift register for RGB data load from ddr2
	// shift 32 clock ticks for dr2 preload RGB data
	shift_register	INST_SHIFT (
		.clock 			(clk),
		.shiftin 		(load_ready),
		.shiftout 		(local_rd_ready),
		.taps 			(shift_taps)
	);
	
	// ddr2 controller
	assign local_rd_req = load_ready;
	
	ddr2_controller INST_DDR2 (
        .clk			(clk),
        .rst_n			(rst_n),
		.local_wr_req	(local_wr_req),
		.local_wr_data	(local_wr_data),
		.local_wr_valid	(local_wr_valid),
		.local_wr_ready	(local_wr_ready),
		.local_rd_req	(local_rd_req),
		.local_rd_ready	(local_rd_ready),
		.local_rd_data	(local_rd_data),
		.local_rd_valid	(local_rd_valid),
        .mem_clk		(mem_clk),
        .mem_clk_n		(mem_clk_n),
        .mem_odt		(mem_odt),
        .mem_cke		(mem_cke),
        .mem_cs_n		(mem_cs_n),
        .mem_ras_n		(mem_ras_n),
        .mem_cas_n		(mem_cas_n),
        .mem_we_n		(mem_we_n),
        .mem_ba			(mem_ba),
        .mem_addr		(mem_addr),
        .mem_dq			(mem_dq),
        .mem_dqs		(mem_dqs),
        .mem_dm			(mem_dm)
    );
