`timescale 1ns/10ps
module dlpc300_config_intf_tb;
    reg 		clk;
	reg			rst_n;

	// dlpc300 configure interface
	reg	[ 7:0]	dlpc_address = 8'h24;
	reg			dlpc_wr_req;
	reg	[31:0]	dlpc_wr_data = 32'h12345678;
	reg			dlpc_wr_valid;
	wire		dlpc_wr_ready;
	reg			dlpc_rd_req;
	wire [31:0]	dlpc_rd_data;
	wire		dlpc_rd_valid;
	reg			dlpc_rd_ready;
	
	// i2c signals
	wire		scl;
	wire		sda;
	integer i,j;
	
	parameter SADR    = 7'b0010_000;
	localparam Tclk = 16;
	
	always #Tclk clk = ~clk;
	
	initial
	begin
		rst_n = 1;
		clk = 0;
		dlpc_wr_req =0;
		dlpc_wr_valid=0;
		dlpc_rd_req=0;
		dlpc_rd_ready=1;
		
		#(10*Tclk);
		rst_n = 0;
		#(100*Tclk);
		rst_n = 1;
			
		repeat(1000) @(posedge clk);
			
		for(i=0;i<256;i=i+4)
			begin
			#1	dlpc_wr_req=1;
			dlpc_wr_data = $random;
			dlpc_address = i;
			 @(posedge clk);
			#1	dlpc_wr_req=0;
			@(negedge dut.stop);
			repeat(1000) @(posedge clk);
		end
		
		repeat(20000) @(posedge clk);
		
//		repeat(1000) @(posedge clk);
//		#1	dlpc_wr_req=1;
//			dlpc_wr_data = $random;
//			dlpc_address = 8'h04;
//			 @(posedge clk);
//			#1	dlpc_wr_req=0;
//			@(negedge dut.stop);
			
		repeat(1000) @(posedge clk);
		for(j=0;j<256;j=j+4) 
		begin
		#1	dlpc_rd_req=1;
			dlpc_address = j;
			 @(posedge clk);
			#1	dlpc_rd_req=0;
			@(negedge dut.stop);
			repeat(1000) @(posedge clk);
		end
			
		#50000;
		repeat(20000) @(posedge clk);
		$stop;
	end
	
	dlpc300_config_intf dut (
		.clk(clk),
		.rst_n(rst_n),
		.dlpc_address(dlpc_address),
		.dlpc_wr_req(dlpc_wr_req),
		.dlpc_wr_data(dlpc_wr_data),
		.dlpc_wr_valid(dlpc_wr_valid),
		.dlpc_wr_ready(dlpc_wr_ready),
		.dlpc_rd_req(dlpc_rd_req),
		.dlpc_rd_data(dlpc_rd_data),
		.dlpc_rd_valid(dlpc_rd_valid),
		.dlpc_rd_ready(dlpc_rd_ready),
	
		.scl(scl),
		.sda(sda)
	);

	
		// hookup i2c slave model
	i2c_slave_model #(SADR) i2c_slave (
		.scl(scl),
		.sda(sda)
	);
	
//	pullup p1(scl); // pullup sda line
	pullup p2(sda); // pullup sda line
	
endmodule
