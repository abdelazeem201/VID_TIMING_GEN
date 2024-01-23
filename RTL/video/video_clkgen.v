/////////////////////////////////////////////////////////////////////
// video_clkgen Module
// Author: Ahmed Abdelazeem
// Description: Verilog module for generating a pixel clock (pclk)
// and its enable signal (pclk_ena) based on an input clock (clk).
/////////////////////////////////////////////////////////////////////

module video_clkgen (
    input  			clk,       // Input clock
    input  			rst_n,     // Active-low asynchronous reset signal
    output 			pclk,      // Pixel clock output
    output 			pclk_ena   // Pixel clock enable output
);

    // Variable declarations
    reg 			pclk_r;      // Pixel clock internal register
    reg 			pclk_ena_r;  // Pixel clock enable internal register

    // Pixel clock is half of the input clock
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            pclk_r <= 1'b0;  // Reset pixel clock to low during reset
        else
            pclk_r <= ~pclk_r;  // Toggle pixel clock on each rising edge of the input clock

    // Pixel clock enable signal is the inverted pixel clock
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            pclk_ena_r <= 1'b0;  // Reset pixel clock enable signal to low during reset
        else
            pclk_ena_r <= ~pclk_ena_r;  // Toggle pixel clock enable on each rising edge of the input clock

    // Assigning outputs
    assign pclk   	= pclk_r;      // Output the pixel clock
    assign pclk_ena = pclk_ena_r;  // Output the pixel clock enable signal

endmodule
