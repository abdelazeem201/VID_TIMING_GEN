`timescale 1ns/10ps
module swap_tim_tb;
    reg 		clk;
	reg			rst_n;
	wire		ena;
	reg			buf_swap;
	wire		hsync;
	wire		vsync;
	wire		daten;

	localparam Tclk = 16;
	
	always #Tclk clk = ~clk;
	
	initial
	begin
		rst_n = 1;
		clk = 0;
		buf_swap=0;
		#(10*Tclk);
		rst_n = 0;
		#(100*Tclk);
		rst_n = 1;
		
		repeat(1000) @(posedge clk);
		#1	buf_swap=1;
		repeat(400) @(posedge clk);
		#1	buf_swap=0;
		
		repeat(8000) @(posedge clk);
		#1	buf_swap=1;
		repeat(800) @(posedge clk);
		#1	buf_swap=0;
		
		repeat(8000) @(posedge clk);
		#1	buf_swap=1;
		repeat(800) @(posedge clk);
		#1	buf_swap=0;
		
		repeat(8000) @(posedge clk);
		#1	buf_swap=1;
		repeat(800) @(posedge clk);
		#1	buf_swap=0;
		
		#50000;
		$stop;
	end	
	
	video_clkgen INST_CLK_GEN (
		.clk	 	(clk),
		.rst_n 	 	(rst_n),
		.pclk	 	(),
		.pclk_ena 	(ena)
	);
	
	swap_tim dut (
		.clk(clk),
		.rst_n(rst_n),
		.ena(ena),
		.Thsync(16),
		.Tgdel(4),
		.Tgate(360),
		.Thlen(400),
		.buf_swap(buf_swap),
		.hsync(hsync),
		.vsync(vsync),
		.daten(daten)
	);
	
	
endmodule
