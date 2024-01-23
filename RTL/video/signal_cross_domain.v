`timescale 1ns/10ps
module signal_cross_domain # (
	parameter	DEFAULT	= 1'b0
	) 
	(
	input 		clkb,
	input		rst_n,
	input 		signal_in_clka,
    output 		signal_out_clkb
);

	reg [3:0] synca_clkb;

	// We use a two-stages shift-register to synchronize signal_in_clka to the clkb clock domain
	always @(posedge clkb or negedge rst_n) 
		if(!rst_n)
			synca_clkb[0] <= DEFAULT;
		else
			synca_clkb[0] <= signal_in_clka; 
		
	always @(posedge clkb) 
		if(!rst_n)
			synca_clkb[1] <= DEFAULT;
		else
			synca_clkb[1] <= synca_clkb[0]; 

	always @(posedge clkb) 
		if(!rst_n)
			synca_clkb[2] <= DEFAULT;
		else
			synca_clkb[2] <= synca_clkb[1];		
		
	always @(posedge clkb) 
		if(!rst_n)
			synca_clkb[3] <= DEFAULT;
		else
			synca_clkb[3] <= synca_clkb[2];		

assign signal_out_clkb = synca_clkb[3];  // new signal synchronized to (=ready to be used in) clkB domain

endmodule
