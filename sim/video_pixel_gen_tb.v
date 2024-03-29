//////////////////////////////////////////////////////////////////////////////
// Module: video_pixel_gen_tb
// Description: Testbench for video_pixel_gen module
// Designer: Ahmed Abdelazeem
// Revision: 1
/*
This testbench instantiates the video pixel generator module and applies various control signals and timing parameters to observe its behavior. The video pixel generator is designed to generate video-related signals such as pixel clock, horizontal sync, vertical sync, blanking, data enable, etc.

Here's a brief overview of the testbench:

Input Signals:

clk: Clock signal
rst_n: Active-low reset signal
ctrl_ven: Video enable signal
ctrl_hsync_pol: Horizontal sync pulse polarization level (positive/negative)
ctrl_vsync_pol: Vertical sync pulse polarization level (positive/negative)
ctrl_blank_pol: Blanking signal polarization level
ctrl_daten_pol: Data enable signal polarization level
Thsync, Thgdel, Thgate, Thlen: Horizontal timing parameters
Tvsync, Tvgdel, Tvgate, Tvlen: Vertical timing parameters
Status Wires:

eoh: End of horizontal signal
eov: End of vertical signal
Pixel-Related Wires:

pclk: Pixel clock
hsync: Horizontal sync pulse
vsync: Vertical sync pulse
blank: Blanking signal
daten: Data enable signal
pdata: Pixel data (24 bits)
Local Parameters:

Tclk: Clock period
Initial Block:

Initializes signals and applies a reset sequence.
Instantiation:

Instantiates the video_pixel_gen module with the specified signals and parameters.
Simulation Stop:

Stops the simulation after a certain number of cycles.
*/
//////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

module video_pixel_gen_tb;

    reg         clk;
    reg         rst_n;

    // Video signal control
    reg         ctrl_ven=1;         // video enable signal
    reg         ctrl_hsync_pol=0;   // horizontal sync pulse polarization level (pos/neg)
    reg         ctrl_vsync_pol=0;   // vertical sync pulse polarization level (pos/neg)
    reg         ctrl_blank_pol=0;   // blank signal polarization level
    reg         ctrl_daten_pol=0;   // data enable signal polarization level

    // horizontal timing settings
    reg [ 7:0]  Thsync=8;           // horizontal sync pulse width (in pixels)
    reg [ 7:0]  Thgdel=12;          // horizontal gate delay (in pixels)
    reg [15:0]  Thgate=100;         // horizontal gate length (number of visible pixels per line)
    reg [15:0]  Thlen=130;          // horizontal length (number of pixels per line)

    // vertical timing settings
    reg [ 7:0]  Tvsync=1;           // vertical sync pulse width (in lines)
    reg [ 7:0]  Tvgdel=2;           // vertical gate delay (in lines)
    reg [15:0]  Tvgate=16;          // vertical gate length (number of visible lines in frame)
    reg [15:0]  Tvlen=22;           // vertical length (number of lines in frame)

    // status wires
    wire        eoh;                // end of horizontal
    wire        eov;                // end of vertical

    // pixel related wires
    wire        pclk;               // pixel clock out
    wire        hsync;              // horizontal sync pulse
    wire        vsync;              // vertical sync pulse
    wire        blank;              // blanking signal
    wire        daten;
    wire [23:0] pdata;

    localparam Tclk = 16;

    always #Tclk clk = ~clk;

    // Initial block
    initial
    begin
        rst_n = 1;
        clk = 0;
        #(10*Tclk);
        rst_n = 0;
        #(100*Tclk);
        rst_n = 1;

        #5000000;
        $stop;
    end

    // Instantiate video_pixel_gen module
    video_pixel_gen dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .ctrl_ven   (ctrl_ven),
        .ctrl_hsync_pol(ctrl_hsync_pol),
        .ctrl_vsync_pol(ctrl_vsync_pol),
        .ctrl_blank_pol(ctrl_blank_pol),
        .ctrl_daten_pol(ctrl_daten_pol),
        .Thsync     (Thsync),
        .Thgdel     (Thgdel),
        .Thgate     (Thgate),
        .Thlen      (Thlen),
        .Tvsync     (Tvsync),
        .Tvgdel     (Tvgdel),
        .Tvgate     (Tvgate),
        .Tvlen      (Tvlen),
        .eoh        (eoh),
        .eov        (eov),
        .pclk       (pclk),
        .hsync      (hsync),
        .vsync      (vsync),
        .blank      (blank),
        .daten      (daten),
        .pdata      (pdata)
    );

endmodule

