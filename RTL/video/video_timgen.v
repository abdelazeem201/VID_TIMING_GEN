`timescale 1ns/10ps
module video_timgen(
	input 			clk,
	input 			clk_ena,
	input 			rst_n,

	// horizontal timing settings inputs
	input 	[7:0] 	Thsync, // horizontal sync pule width (in pixels)
	input 	[7:0]	Thgdel, // horizontal gate delay
	input 	[15:0] 	Thgate, // horizontal gate (number of visible pixels per line)
	input 	[15:0] 	Thlen,  // horizontal length (number of pixels per line)

	// vertical timing settings inputs
	input 	[7:0] 	Tvsync, // vertical sync pule width (in pixels)
	input 	[7:0] 	Tvgdel, // vertical gate delay
	input 	[15:0] 	Tvgate, // vertical gate (number of visible pixels per line)
	input 	[15:0] 	Tvlen,  // vertical length (number of pixels per line)

	// outputs
	output 			eol,  // end of line
	output 			eof,  // end of frame
	output 			gate, // vertical AND horizontal gate (logical AND function)

	output 			hsync, // horizontal sync pulse
	output 			vsync, // vertical sync pulse
	output 			blank // blank signal
);

	// variable declarations
	wire hgate, vgate;
	wire hdone;


	// hookup horizontal timing generator
	video_tim INST_HOR_GEN(
		.clk	(clk),
		.ena	(clk_ena),
		.rst_n	(rst_n),
		.Tsync	(Thsync),
		.Tgdel	(Thgdel),
		.Tgate	(Thgate),
		.Tlen	(Thlen),
		.sync	(hsync),
		.gate	(hgate),
		.done	(hdone)
	);


	// hookup vertical timing generator
	wire vclk_ena = hdone & clk_ena;

	video_tim INST_VER_GEN(
		.clk	(clk),
		.ena	(vclk_ena),
		.rst_n	(rst_n),
		.Tsync	(Tvsync),
		.Tgdel	(Tvgdel),
		.Tgate	(Tvgate),
		.Tlen	(Tvlen),
		.sync	(vsync),
		.gate	(vgate),
		.done	(eof)
	);

	// assign outputs
	assign eol  = hdone;
	assign gate = hgate & vgate;
	assign blank = ~gate;
	
endmodule
