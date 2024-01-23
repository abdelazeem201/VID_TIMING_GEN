`timescale 1ns/10ps
module dlpc300_config_intf (
    input 				clk,
	input				rst_n,

	// dlpc300 configure interface
	input	[ 7:0]		dlpc_address,
	input				dlpc_wr_req,
	input	[31:0]		dlpc_wr_data,
	input				dlpc_wr_valid,
	output				dlpc_wr_ready,
	input				dlpc_rd_req,
	output reg	[31:0]	dlpc_rd_data,
	output reg			dlpc_rd_valid,
	input				dlpc_rd_ready,
	
	// i2c signals
	output				scl,
	inout				sda
);

	// i2c core commands
	localparam PRER_LO 	= 3'b000;
	localparam PRER_HI 	= 3'b001;
	localparam CTR     	= 3'b010;
	localparam RXR     	= 3'b011;
	localparam TXR     	= 3'b011;
	localparam CR      	= 3'b100;
	localparam SR      	= 3'b100;

	// i2c line commands
	localparam RD      	= 1'b1;
	localparam WR      	= 1'b0;
	localparam SADR    	= 7'b0010_000;
	localparam SUB_ADR	= 8'h15;
	
	parameter DWIDTH 	= 32;
	parameter AWIDTH 	= 32;
	
	reg		[3:0]	cstate, nstate;
	localparam	IDLE_S	= 4'd0;
	localparam	SADR_S	= 4'd1;
	localparam	SCMD_S	= 4'd2;
	localparam	SBADR_S	= 4'd3;
	localparam	RADR_S	= 4'd4;	// register address
	localparam	WDAT_S	= 4'd5;
	localparam	RDAT_S	= 4'd6;
	localparam	STAR_S	= 4'd7;	// status read
	localparam	STAL_S	= 4'd8; // status load
	localparam	STAC_S	= 4'd9; // status check
	localparam	LDAT_S	= 4'd10;
	localparam	LBYTE_S	= 4'd11;

	// wishbone signals
	reg	 	[31:0] 	wb_adr;
	wire 	[ 7:0] 	wb_din;
	reg	 	[ 7:0] 	wb_dout;
	reg	 			wb_we;
	reg	 			wb_stb;
	reg	 			wb_cyc;
	wire 			wb_ack;
	wire 			wb_inta;
	
	// I2C pad signals
	// i2c clock line
	wire  			scl_pad_i;       // SCL-line input
	wire			scl_pad_o;       // SCL-line output (always 1'b0)
	wire 			scl_padoen_oe;   // SCL-line output enable (active low)

	// i2c data line
	wire  			sda_pad_i;       // SDA-line input
	wire 			sda_pad_o;       // SDA-line output (always 1'b0)
	wire 			sda_padoen_oe;   // SDA-line output enable (active low)
	
	// command register bit 
	wire	[ 7:0]	cmdr;
	reg				start;
	reg				stop;
	reg				write;
	reg				read;
	reg				ack;
	reg				iack;
	
	// internal signals
	reg				wena;
	reg				rena;
	reg				aena;
	reg				dena;
	reg				saena;
	reg				clear;
	reg 	[ 7:0] 	q, qq;
	reg				qq_valid;
	reg				addr_up;
	reg				data_up;
	reg		[ 2:0]	byte_cnt;
	reg				clr_cnt;
	reg				read_whit;
	reg				read_rhit;
	reg				sub_addr_up;
	reg				rlast_byte;
	reg				rd_valid;
	reg				rd_valid_d;
	reg	 	[31:0] 	rd_sreg;
	
	
	assign dlpc_wr_ready = 1'b1;
	
	always @(posedge clk)
		if(rd_valid_d)
			dlpc_rd_data <= rd_sreg;
			
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			dlpc_rd_valid <= 1'b0;
		else if(dlpc_rd_ready)
			dlpc_rd_valid <= rd_valid_d;
	
	always @(posedge clk)
		if(qq_valid)
			rd_sreg <= {rd_sreg[23:0], qq};
			
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			rd_valid_d <= 1'b0;
		else
			rd_valid_d <= rd_valid;
	
	// command register
	assign cmdr = {start, stop, read ,write, ack, 2'b00, iack};
	
	// i2c core access state machine
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			cstate <= IDLE_S;
		else
			cstate <= nstate;
			
	always @(*)
	begin
		nstate = cstate;
		
		case(cstate)
		IDLE_S:
		begin
			if(dlpc_wr_req | dlpc_rd_req)
				nstate = SADR_S;
		end
		
		SADR_S:
		begin
			if(wb_ack)
				nstate = SCMD_S;
		end
		
		SBADR_S:
		begin
			if(wb_ack)
				nstate = SCMD_S;
		end
		
		SCMD_S:
		begin
			if(wb_ack)
				nstate = STAR_S;
		end
		
		STAR_S:
		begin
			nstate = STAL_S;
		end
		
		STAL_S:
		begin
			if(wb_ack)
				nstate = STAC_S;
		end
		
		STAC_S:
		begin
			if(!q[1])
			begin
				case({rena, wena, aena, dena, stop, saena, read_rhit, rlast_byte})
				8'b10000000: nstate = SBADR_S;
				8'b01000000: nstate = RADR_S;
				8'b00100000: if(read_whit)
								nstate = SADR_S;
							else 
								nstate = WDAT_S;
				8'b00010000: if(byte_cnt[2])
								nstate = SCMD_S;
							else
								nstate = WDAT_S;
				8'b00001000: nstate = IDLE_S;
				8'b00000100: nstate = RADR_S;
				8'b00000010, 8'b00001010: nstate = LDAT_S;
				8'b00000001: nstate = LBYTE_S;
				endcase
			end
			else
				nstate = STAR_S;
		end
		
		RADR_S:
		begin
			if(wb_ack)
				nstate = SCMD_S;
		end
		
		WDAT_S:
		begin
			if(wb_ack)
				nstate = SCMD_S;
		end
		
		LDAT_S:
		begin
			if(~|byte_cnt)
				nstate = RDAT_S;
			else if(wb_ack)
				nstate = RDAT_S;
		end
		
		RDAT_S:
		begin
			nstate = SCMD_S;
		end
		
		LBYTE_S:
		begin
			if(wb_ack)
				nstate = IDLE_S;
		end
	
		endcase
	end
	
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
		begin
			wb_idle;
			start	<= 1'b0;
			stop	<= 1'b0;
			write	<= 1'b0;
			read	<= 1'b0;
			ack		<= 1'b0;
			iack	<= 1'b0;
			clear	<= 1'b0;
			addr_up	<= 1'b0;
			data_up <= 1'b0;
			clr_cnt <= 1'b0;
			read_whit <= 1'b0;
			read_rhit <= 1'b0;
			sub_addr_up	<= 1'b0;
			qq_valid <= 1'b0;
			rlast_byte <= 1'b0;
			rd_valid <= 1'b0;
		end
		else
		begin
			case(cstate)
			IDLE_S:
			begin
				wb_idle;
				start	<= 1'b0;
				stop	<= 1'b0;
				write	<= 1'b0;
				read	<= 1'b0;
				clear	<= 1'b0;
				clr_cnt <= 1'b0;
				ack 	<= 1'b0;
				rlast_byte <= 1'b0;
				qq_valid <= 1'b0;
				rd_valid <= 1'b0;
				
				if(dlpc_rd_req)
					read_whit <= 1'b1;
			end
			
			SADR_S:
			begin
				start	<= 1'b1;
				write	<= 1'b1;
				
				if(read_rhit)
					wb_write(TXR, {SADR,RD}); // present slave address, set read-bit
				else
					wb_write(TXR, {SADR,WR}); // present slave address, set write-bit
				
				if(wb_ack)
					wb_idle;
			end
			
			SBADR_S:
			begin
				clear 	<= 1'b0;
				start	<= 1'b0;
				sub_addr_up	<= 1'b1;
				wb_write(TXR, SUB_ADR); // present sub address
				if(wb_ack)
					wb_idle;
			end
			
			SCMD_S:
			begin
				addr_up	<= 1'b0;
				data_up <= 1'b0;
				sub_addr_up	<= 1'b0;
				wb_write(CR, cmdr); // set command (start, write)
				if(wb_ack)
					wb_idle;
			end
			
			STAR_S:
			begin
				clear 	<= 1'b0;
				data_up <= 1'b0;
					
				wb_read(SR);
			end
			
			STAL_S:
			begin
				if(wb_ack)
				begin
					q <= wb_din;
					wb_idle;
				end
			end
			
			STAC_S:
			begin
				if(!q[1])
				begin
					clear <= 1'b1;
					wb_idle;
					if(&byte_cnt[1:0])
					begin
						stop	<= 1'b1;					
						if(read_rhit)
							ack <= 1'b1; // nack
					end
					
					if(byte_cnt[2])
						clr_cnt <= 1'b1;
						
					if(read_whit & aena)
					begin
						read_whit <= 1'b0;
						read_rhit <= 1'b1;
					end
					
					if(read_rhit & byte_cnt[2])
					begin
						clr_cnt <= 1'b1;
						read_rhit <= 1'b0;
						stop	<= 1'b0;
						rlast_byte <= 1'b1;
					end
				end
				else
					wb_idle;
			end
			
			RADR_S:	
			begin
				start	<= 1'b0;
				clear 	<= 1'b0;
				addr_up	<= 1'b1;
				wb_write(TXR, dlpc_address); // present slave's memory address
				if(wb_ack)
					wb_idle;
			end
			
			WDAT_S:
			begin
				clear 	<= 1'b0;
				case(byte_cnt)
				2'b00: wb_write(TXR, dlpc_wr_data[31:24]); // present data
				2'b01: wb_write(TXR, dlpc_wr_data[23:16]);
				2'b10: wb_write(TXR, dlpc_wr_data[15: 8]);
				2'b11: wb_write(TXR, dlpc_wr_data[ 7: 0]);
				endcase
				
				if(wb_ack)
				begin
					data_up <= 1'b1;
					wb_idle;
				end
			end
			
			LDAT_S:
			begin
				start	<= 1'b0;
				clear 	<= 1'b0;
				read	<= 1'b1;
				write	<= 1'b0;
				
				if(|byte_cnt)
					wb_read(RXR);
					
				if(wb_ack)
				begin
					qq <= wb_din;
					qq_valid <= 1'b1;
					wb_idle;
				end
			end
			
			RDAT_S:
			begin
				start	<= 1'b0;
				clear 	<= 1'b0;
				read	<= 1'b1;
				write	<= 1'b0;
				qq_valid <= 1'b0;
				data_up <= 1'b1;
			end
			
			LBYTE_S:
			begin
				wb_read(RXR);
					
				if(wb_ack)
				begin
					qq <= wb_din;
					qq_valid <= 1'b1;
					rd_valid <= 1'b1;
					wb_idle;
				end
			end
			
			endcase
		end
	
	// write operation enable
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			wena <= 1'b0;
		else if(clear)
			wena <= 1'b0;
		else if(dlpc_wr_req)
			wena <= 1'b1;

	// read operation enable
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			rena <= 1'b0;
		else if(clear)
			rena <= 1'b0;
		else if(dlpc_rd_req)
			rena <= 1'b1;	
	
	// address enable
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			aena <= 1'b0;
		else if(clear)
			aena <= 1'b0;
		else if(addr_up)
			aena <= 1'b1;
			
	// sub address enable
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			saena <= 1'b0;
		else if(clear)
			saena <= 1'b0;
		else if(sub_addr_up)
			saena <= 1'b1;
			
	// data enable
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			dena <= 1'b0;
		else if(clear)
			dena <= 1'b0;
		else if(data_up)
			dena <= 1'b1;
	
	// data byte count
	always @(posedge clk or negedge rst_n)
		if (!rst_n)	
			byte_cnt <= 3'b000;
		else if(clr_cnt)
			byte_cnt <= 3'b000;
		else if(data_up)
			byte_cnt <= byte_cnt + 1'b1;
			
	// Wishbone write cycle task
	task wb_write;
		input	[AWIDTH-1:0]	a;
		input	[DWIDTH-1:0]	d;
		
		begin
			// assert wishbone signal
			wb_adr  <= a;
			wb_dout <= d;
			wb_cyc  <= 1'b1;
			wb_stb  <= 1'b1;
			wb_we   <= 1'b1;
		end
	endtask

	// Wishbone read cycle task
	task wb_read;
		input	[AWIDTH-1:0]	a;

		begin
			// assert wishbone signals
			wb_adr  <= a;
			wb_dout <= {DWIDTH{1'b0}};
			wb_cyc  <= 1'b1;
			wb_stb  <= 1'b1;
			wb_we   <= 1'b0;
		end
	endtask
	
	// Wishbone data load
//	task wb_data;
//		output	[DWIDTH-1:0]	d;
//
//		begin
//			// load data
//			d    <= wb_din;
//		end
//	endtask
	
	// Wishbone bus reset
	task wb_idle;

		begin
			// assert wishbone signals
			wb_adr  <= {AWIDTH{1'b1}};
			wb_dout <= {DWIDTH{1'b0}};
			wb_cyc  <= 1'b0;
			wb_stb  <= 1'b0;
			wb_we   <= 1'b0;
		end
	endtask


	// The tri-state buffers for the SCL and SDA lines
	assign scl = scl_padoen_oe ? 1'b1 : scl_pad_o; 
	assign sda = sda_padoen_oe ? 1'bz : sda_pad_o; 
	assign scl_pad_i = scl; 
	assign sda_pad_i = sda; 
  
	// hookup wishbone_i2c_master core
	i2c_master_top INST_I2C_CORE (

		// wishbone interface
		.wb_clk_i(clk),
		.wb_rst_i(1'b0),
		.arst_i(rst_n),
		.wb_adr_i(wb_adr[2:0]),
		.wb_dat_i(wb_dout),
		.wb_dat_o(wb_din),
		.wb_we_i(wb_we),
		.wb_stb_i(wb_stb),
		.wb_cyc_i(wb_cyc),
		.wb_ack_o(wb_ack),
		.wb_inta_o(wb_inta),

		// i2c signals
		.scl_pad_i(scl_pad_i),
		.scl_pad_o(scl_pad_o),
		.scl_padoen_o(scl_padoen_oe),
		.sda_pad_i(sda_pad_i),
		.sda_pad_o(sda_pad_o),
		.sda_padoen_o(sda_padoen_oe)
	);
	
endmodule
