/////////////////////////////////////////////////////////////////////
// video_timgen Module
// Author: Ahmed Abdelazeem
// Description: Verilog module for generating timing signals for
// horizontal and vertical synchronization. It uses two instances
// of the video_tim module (horizontal and vertical timing generators)
// to create synchronization pulses, gates, and end-of-line/frame signals.
/////////////////////////////////////////////////////////////////////

module video_timgen(
    input 			clk,      // Master clock
    input 			clk_ena,  // Clock enable
    input 			rst_n,    // Active-low asynchronous reset

    // Horizontal timing settings inputs
    input 	[7:0] 	Thsync,   // Horizontal sync pulse width (in pixels)
    input 	[7:0]	Thgdel,   // Horizontal gate delay
    input 	[15:0] 	Thgate,   // Horizontal gate (number of visible pixels per line)
    input 	[15:0] 	Thlen,    // Horizontal length (number of pixels per line)

    // Vertical timing settings inputs
    input 	[7:0] 	Tvsync,   // Vertical sync pulse width (in pixels)
    input 	[7:0] 	Tvgdel,   // Vertical gate delay
    input 	[15:0] 	Tvgate,   // Vertical gate (number of visible pixels per line)
    input 	[15:0] 	Tvlen,    // Vertical length (number of pixels per line)

    // Outputs
    output 			eol,      // End of line
    output 			eof,      // End of frame
    output 			gate,     // Vertical AND horizontal gate (logical AND function)
    output 			hsync,    // Horizontal sync pulse
    output 			vsync,    // Vertical sync pulse
    output 			blank     // Blank signal
);

    // Variable declarations
    wire hgate, vgate;
    wire hdone;

    // Hookup horizontal timing generator
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

    // Hookup vertical timing generator
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

    // Assign outputs
    assign eol  = hdone;
    assign gate = hgate & vgate;
    assign blank = ~gate;

endmodule
