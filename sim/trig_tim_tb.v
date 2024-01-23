`timescale 1ns/10ps
module trig_tim_tb;
    reg 		clk;
	reg			rst_n;
	wire		ena;
	reg			trig;
	wire		hsync;
	wire		vsync;
	wire		daten;

	localparam Tclk = 16;
	
	always #Tclk clk = ~clk;
	
	initial
	begin
		rst_n = 1;
		clk = 0;
		trig=0;
		#(10*Tclk);
		rst_n = 0;
		#(100*Tclk);
		rst_n = 1;
		
		repeat(1000) @(posedge clk);
		#1	trig=1;
		 @(posedge clk);
		#1	trig=0;
		
		repeat(8000) @(posedge clk);
		#1	trig=1;
		 @(posedge clk);
		#1	trig=0;
		
		#50000;
		$stop;
	end	
	
	video_clkgen INST_CLK_GEN (
		.clk	 	(clk),
		.rst_n 	 	(rst_n),
		.pclk	 	(),
		.pclk_ena 	(ena)
	);
	
	trig_tim dut (
		.clk(clk),
		.rst_n(rst_n),
		.ena(ena),
		.Thsync(16),
		.Thlen(200),
		.trig(trig),
		.hsync(hsync),
		.vsync(vsync),
		.daten(daten)
	);
	
endmodule
