`timescale 1ns/10ps
module video_clkgen (
	input  			clk,    
	input  			rst_n,       
	output 			pclk,   	// pixel clock out
	output 			pclk_ena   // pixel clock enable output
);

	// variable declarations
	reg 			pclk_r;
	reg 			pclk_ena_r;


	// pixel clock is half of the input clock
	always @(posedge clk or negedge rst_n)
	  if (!rst_n)
	    pclk_r <= 1'b0;
	  else
	    pclk_r <= ~pclk_r;

	always @(posedge clk or negedge rst_n)
	  if (!rst_n)
	    pclk_ena_r <= 1'b0;
	  else
	    pclk_ena_r <= ~pclk_ena_r;

	assign pclk   	= pclk_r;
	assign pclk_ena = pclk_ena_r;

endmodule 