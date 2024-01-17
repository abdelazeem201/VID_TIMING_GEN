////////////////////////////////////////////////////////////////////////////////
// Module: ddr2_controller
// Description: Verilog module for controlling communication between a host and
//              an external DDR2 memory. It includes interfaces for data writes
//              and reads, along with signals for managing the DDR2 port.
// Designer: Ahmed Abdelazeem
// Version: 1.0
// Date: January 1, 2024
////////////////////////////////////////////////////////////////////////////////

module ddr2_controller (
	input				clk,
	input				rst_n,
	
	// data from host to ddr2
	input				local_wr_req,	// write one buffer in each write request
	input	[23:0]		local_wr_data,
	input				local_wr_valid,
	output				local_wr_ready, // it indicates that the memory controller is ready to accept data
	// load data from ddr2, read one line data each read request
	input				local_rd_req,	// this signal read data from ddr2 to local buffer
	input				local_rd_ready,	// this signal indicates that the video controller is ready to accept data, it will read data from local fifo
	output	[23:0]		local_rd_data,
	output				local_rd_valid,
	
	// external ddr2 port
	output  [15:0] 		mem_addr,
	output  [2:0] 		mem_ba,
	output           	mem_cas_n,
	output  			mem_cke,
	inout   			mem_clk,
	inout   			mem_clk_n,
	output  			mem_cs_n,
	output  [1:0] 		mem_dm,
	inout   [15:0] 		mem_dq,
	inout   [1:0] 		mem_dqs,
	output  [0:0] 		mem_odt,
	output           	mem_ras_n,
	output           	mem_we_n
);

	wire				mem_local_burstbegin;
	wire    [27:0] 		mem_local_addr;
	wire    [3:0] 		mem_local_be;
	wire    [9:0] 		mem_local_col_addr;
	wire             	mem_local_cs_addr;
    wire    [31:0] 		mem_local_rdata;
    wire            	mem_local_rdata_valid;
    wire             	mem_local_read_req;
    wire             	mem_local_ready;
    wire    [2:0] 		mem_local_size;
    wire    [31:0] 		mem_local_wdata;
    wire             	mem_local_write_req;
	wire				mem_local_init_done;
	wire             	tie_high;
	wire             	tie_low;
	wire            	mem_aux_full_rate_clk;
	wire             	mem_aux_half_rate_clk;
	wire				phy_clk;
	
	// write fifo signals
	wire	[23:0]		wfifo_rdata;
	wire				wfifo_rdreq;
	reg					wfifo_rdata_valid;
	wire				wfifo_rdempty;
	wire				wfifo_wrfull;
	
	// read fifo signals
	wire	[23:0]		rfifo_wdata;
	wire				rfifo_wdreq;
	wire	[23:0]		rfifo_rdata;
	//wire				rfifo_rdreq;
	reg					rfifo_rdata_valid;
	wire				rfifo_rdempty;
	wire				rfifo_wrfull;
	
	// handshake signals
	wire	[1:0]		sig_wdata;
	wire				sig_wdreq;
	wire	[1:0]		sig_rdata;
	wire				sig_rdreq;
	wire				sig_rdempty;
	wire				sig_wrfull;
	
	reg					local_wr_req_d;
	reg					local_rd_req_d;
	wire				wr_req;
	wire				rd_req;

	// handshake fifo for write to ddr2
	assign wfifo_rdreq = ~wfifo_rdempty;
	handshake_wfifo	INST_HANDSHAKE_WFIFO (
		.wrclk 	( clk ),
		.data 	( local_wr_data ),
		.wrreq 	( local_wr_valid & ~wfifo_wrfull ),
		.rdclk 	( phy_clk ),
		.rdreq 	( wfifo_rdreq ),
		.q 		( wfifo_rdata ),
		.rdempty( wfifo_rdempty ),
		.wrfull ( wfifo_wrfull )
	);
	
	handshake_rfifo	INST_HANDSHAKE_RFIFO (
		.wrclk 	( phy_clk ),
		.data 	( rfifo_wdata ),
		.wrreq 	( rfifo_wdreq & ~rfifo_wrfull ),
		.rdclk 	( clk ),
		.rdreq 	( local_rd_ready & ~rfifo_rdempty ),
		.q 		( rfifo_rdata ),
		.rdempty( rfifo_rdempty ),
		.wrfull ( rfifo_wrfull )
	);
	
	// signal handshake
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			local_wr_req_d <= 1'b0;
		else
			local_wr_req_d <= local_wr_req;
			
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			local_rd_req_d <= 1'b0;
		else
			local_rd_req_d <= local_rd_req;		
		
	assign sig_wdata = {local_wr_req, local_rd_req};
	assign sig_wdreq = local_wr_req | local_wr_req_d | local_rd_req | local_rd_req_d;
	assign sig_rdreq = ~sig_rdempty;
	handshake_sig	INST_HANDSHAKE_SIG (
		.wrclk 	( clk ),
		.data 	( sig_wdata ),
		.wrreq 	( sig_wdreq & ~sig_wrfull ),
		.rdclk 	( phy_clk ),
		.rdreq 	( sig_rdreq ),
		.q 		( sig_rdata ),
		.rdempty( sig_rdempty ),
		.wrfull ( sig_wrfull )
	);	
	
	assign wr_req = sig_rdata[1];
	assign rd_req = sig_rdata[0];

	//connect up the column address bits, dropping 1 bits from example driver output because of 2:1 data rate
	assign mem_local_addr[8:0] = mem_local_col_addr[9:1];
	
	always @(posedge phy_clk or negedge rst_n)
		if(!rst_n)
			wfifo_rdata_valid <= 1'b0;
		else	
			wfifo_rdata_valid <= wfifo_rdreq;
	
	ddr2_core_driver INST_DDR2_CORE_DRIVER (
		.clk 				(phy_clk),
		.rst_n 				(rst_n),
		.to_ddr2_strb		(wr_req),
		.to_ddr2_req		(wfifo_rdreq),
		.to_ddr2_data		(wfifo_rdata),
		.from_ddr2_strb		(rd_req),
		.from_ddr2_data		(rfifo_wdata),
		.from_ddr2_data_valid(rfifo_wdreq),
		
		.local_bank_addr 	(mem_local_addr[27:25]),
		.local_be 			(mem_local_be),
		.local_burstbegin 	(mem_local_burstbegin),
		.local_col_addr 	(mem_local_col_addr),
		.local_cs_addr 		(mem_local_cs_addr),
		.local_rdata 		(mem_local_rdata),
		.local_rdata_valid	(mem_local_rdata_valid),
		.local_read_req		(mem_local_read_req),
		.local_ready		(mem_local_ready),
		.local_row_addr		(mem_local_addr[24:9]),
		.local_size			(mem_local_size),
		.local_wdata		(mem_local_wdata),
		.local_write_req	(mem_local_write_req)
	);
	
	assign tie_high = 1'b1;
	assign tie_low = 1'b0;
	
	ddr2_core INST_DDR2_CORE (
		.aux_full_rate_clk (mem_aux_full_rate_clk),
		.aux_half_rate_clk (mem_aux_half_rate_clk),
		.global_reset_n (rst_n),
		.local_address (mem_local_addr),
		.local_be (mem_local_be),
		.local_burstbegin (mem_local_burstbegin),
		.local_init_done (mem_local_init_done),
		.local_rdata (mem_local_rdata),
		.local_rdata_valid (mem_local_rdata_valid),
		.local_read_req (mem_local_read_req),
		.local_ready (mem_local_ready),
		.local_refresh_ack (),
		.local_size (mem_local_size),
		.local_wdata (mem_local_wdata),
		.local_write_req (mem_local_write_req),
		.mem_addr (mem_addr[15:0]),
		.mem_ba (mem_ba),
		.mem_cas_n (mem_cas_n),
		.mem_cke (mem_cke),
		.mem_clk (mem_clk),
		.mem_clk_n (mem_clk_n),
		.mem_cs_n (mem_cs_n),
		.mem_dm (mem_dm[1:0]),
		.mem_dq (mem_dq),
		.mem_dqs (mem_dqs[1:0]),
		.mem_odt (mem_odt),
		.mem_ras_n (mem_ras_n),
		.mem_we_n (mem_we_n),
		.phy_clk (phy_clk),
		.pll_ref_clk (clk),
		.reset_phy_clk_n (reset_phy_clk_n),
		.reset_request_n (),
		.soft_reset_n (tie_high)
    );

endmodule
