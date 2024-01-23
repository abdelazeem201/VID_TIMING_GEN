`timescale 1ns/10ps
module video_pixel_gen (
	input 			clk,
	input			rst_n,
	
	// video signal control
	input 			ctrl_ven,    	// video enable signal
	input        	ctrl_hsync_pol, // horizontal sync pulse polarization level (0: active high; 1: active low)
	input        	ctrl_vsync_pol, // vertical sync pulse polarization level (0: active high; 1: active low)
	input 			ctrl_blank_pol, // blank signal polarization level (0: active high; 1: active low)
	input 			ctrl_daten_pol, // data enable signal polarization level (0: active high; 1: active low)

	// horizontal timing settings
	input 	[ 7:0] 	Thsync, // horizontal sync pulse width (in pixels)
	input 	[ 7:0] 	Thgdel,	// horizontal gate delay (in pixels)
	input 	[15:0] 	Thgate, // horizontal gate length (number of visible pixels per line)
	input 	[15:0] 	Thlen,  // horizontal length (number of pixels per line)

	// vertical timing settings
	input 	[ 7:0] 	Tvsync, // vertical sync pulse width (in lines)
	input 	[ 7:0] 	Tvgdel, // vertical gate delay (in lines)
	input 	[15:0] 	Tvgate, // vertical gate length (number of visible lines in frame)
	input	[15:0] 	Tvlen,  // vertical length (number of lines in frame)

	// status outputs
	output 			eoh, // end of horizontal
	output 			eov, // end of vertical
	
	// pixel data load control
	output			load_ready,
	input	[23:0]	load_data,
	input			load_valid,

	// pixel related outputs
	output 			pclk,	// pixel clock out
	output reg 		hsync, // horizontal sync pulse
	output reg 		vsync, // vertical sync pulse
	output reg		blank, // blanking signal
	output reg		daten,
	output [23:0] 	pdata
);

	wire			gate;
	wire			pclk_ena;
	wire 			ihsync;
	wire			ivsync;
	wire			iblank;
	wire			idaten;
	
	assign load_ready = gate;

	//**********************************************
	// Pixel Clock generator
	//**********************************************
	video_clkgen INST_CLK_GEN (
		.clk	 	(clk),
		.rst_n 	 	(rst_n),
		.pclk	 	(pclk),
		.pclk_ena 	(pclk_ena)
	);
	
	//**********************************************
	// Timing generator
	//**********************************************
	// hookup video timing generator
	video_timgen INST_TIMGEN (
		.clk	 	(clk),
		.clk_ena 	(pclk_ena),
		.rst_n 	 	(rst_n),
		.Thsync  	(Thsync),
		.Thgdel  	(Thgdel),
		.Thgate  	(Thgate),
		.Thlen   	(Thlen),
		.Tvsync  	(Tvsync),
		.Tvgdel  	(Tvgdel),
		.Tvgate  	(Tvgate),
		.Tvlen   	(Tvlen),
		.eol     	(eoh),
		.eof     	(eov),
		.gate    	(gate),
		.hsync   	(ihsync),
		.vsync   	(ivsync),
		.blank   	(iblank)
	);

	always @(posedge clk)
		if (pclk_ena)
	    begin
	        hsync <= ihsync ^ ctrl_hsync_pol;
	        vsync <= ivsync ^ ctrl_vsync_pol;
	        blank <= iblank ^ ctrl_blank_pol;
			daten <= idaten ^ ctrl_daten_pol;
	    end
		
endmodule
