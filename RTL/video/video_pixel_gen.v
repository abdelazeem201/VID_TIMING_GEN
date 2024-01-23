/////////////////////////////////////////////////////////////////////
// video_pixel_gen Module
// Author: Ahmed Abdelazeem
// Description: Verilog module for generating video pixel signals
// based on timing and control signals. It includes a pixel clock
// generator (video_clkgen) and a timing generator (video_timgen).
/////////////////////////////////////////////////////////////////////

module video_pixel_gen (
    input 			clk,           // Input clock
    input			rst_n,         // Active-low asynchronous reset signal

    // Video signal control
    input 			ctrl_ven,      // Video enable signal
    input        	ctrl_hsync_pol, // Horizontal sync pulse polarization level (0: active high; 1: active low)
    input        	ctrl_vsync_pol, // Vertical sync pulse polarization level (0: active high; 1: active low)
    input 			ctrl_blank_pol, // Blanking signal polarization level (0: active high; 1: active low)
    input 			ctrl_daten_pol, // Data enable signal polarization level (0: active high; 1: active low)

    // Horizontal timing settings
    input 	[ 7:0] 	Thsync,   // Horizontal sync pulse width (in pixels)
    input 	[ 7:0] 	Thgdel,   // Horizontal gate delay (in pixels)
    input 	[15:0] 	Thgate,   // Horizontal gate length (number of visible pixels per line)
    input 	[15:0] 	Thlen,    // Horizontal length (number of pixels per line)

    // Vertical timing settings
    input 	[ 7:0] 	Tvsync,   // Vertical sync pulse width (in lines)
    input 	[ 7:0] 	Tvgdel,   // Vertical gate delay (in lines)
    input 	[15:0] 	Tvgate,   // Vertical gate length (number of visible lines in frame)
    input	[15:0] 	Tvlen,    // Vertical length (number of lines in frame)

    // Status outputs
    output 			eoh,       // End of horizontal
    output 			eov,       // End of vertical

    // Pixel data load control
    output			load_ready,
    input	[23:0]	load_data,
    input			load_valid,

    // Pixel-related outputs
    output 			pclk,      // Pixel clock out
    output reg 		hsync,     // Horizontal sync pulse
    output reg 		vsync,     // Vertical sync pulse
    output reg		blank,     // Blanking signal
    output reg		daten,     // Data enable signal
    output [23:0] 	pdata      // Pixel data
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
    // Hookup video timing generator
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
