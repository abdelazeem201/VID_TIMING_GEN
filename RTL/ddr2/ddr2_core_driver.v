
`timescale 1 ps/1 ps


module ddr2_core_driver #(
	parameter VDATA_NUM	= 64,	
	parameter HDATA_NUM	= 4,
	parameter MAX_ROW	= 256,  // Maximum value is 2^(row bits) -1, while minimum value is 0
	parameter MAX_COL 	= 16, // Maximum value is 2^(column bits) - (LOCAL_BURST_LEN_s * dwidth_ratio (aka half-rate (4) or full-rate (2))), while minimum value is 0 for Half rate and (LOCAL_BURST_LEN_s * dwidth_ratio) for Full rate
	parameter MAX_BANK 	= 4,  // Decrease MAX_BANK to test lesser bank address, minimum value is 0
	parameter MAX_CHIPSEL = 0, //Decrease MAX_CHIPSEL to test lesser memory chip, minimum value is MIN_CHIPSEL
	parameter MIN_CHIPSEL = 0
	)(
	input            	clk,
	input            	rst_n,
	
	// data operation with fifo handshake
	// these data write to ddr2
	input				to_ddr2_strb,	// write one buffer when receive a strobe signal
	input				to_ddr2_req,				
	input	[23:0]		to_ddr2_data,
	// load data from ddr2 via these signals
	input				from_ddr2_strb,	// get one line image data in each strobe signal
	output  reg [23:0] 	from_ddr2_data,
	output	reg			from_ddr2_data_valid,
	output	reg	[1:0]	buf_id,		// indicate which buffer using on current operation
	
	// ddr2 core interface
	input	[31:0] 		local_rdata,
	input            	local_rdata_valid,
	input            	local_ready,
	output  [2:0] 		local_bank_addr,
	output  [3:0] 		local_be,
	output           	local_burstbegin,
	output  [9:0] 		local_col_addr,
	output           	local_cs_addr,
	output           	local_read_req,
	output  [15:0] 		local_row_addr,
	output  [2:0] 		local_size,
	output  [31:0] 		local_wdata,
	output           	local_write_req
);

	wire    [2:0] 		LOCAL_BURST_LEN_s;
	reg					reset_address;
	reg 				burst_begin;
	wire    [4:0] 		addr_value;
	reg     [2:0] 		bank_addr;
	reg     [9:0] 		col_addr;
	reg              	cs_addr;
	reg              	full_burst_on;
	wire    [9:0] 		max_col_value;
	wire             	reached_max_address;
	reg              	read_req;
	reg     [15:0] 		row_addr;
	wire    [2:0] 		size;
	wire    [31:0] 		wdata;
	wire             	wdata_req;
	reg              	write_req;
	wire				reached_max_hcnt;
	wire				reached_buf_tail;
	reg		[9:0]		v_cnt;
	reg		[9:0]		h_cnt;
	reg					wr_rd_hit;
	
	reg     [2:0] state;
	localparam	IDLE	= 3'd0;
	localparam	WRITE	= 3'd1;
	localparam	READ	= 3'd2;

	
	assign max_col_value = ((addr_value == 2) == 0)? MAX_COL : (MAX_COL + 2);

	assign reached_max_address = ((col_addr == (max_col_value)) & (row_addr == MAX_ROW) & (bank_addr == MAX_BANK) & (cs_addr == MAX_CHIPSEL));
	assign addr_value = ((write_req & ~full_burst_on) == 0)? 4 : 2;
	assign reached_max_hcnt = (h_cnt == (HDATA_NUM-1));
	assign reached_buf_tail = reached_max_hcnt & (v_cnt == (VDATA_NUM-1));
	
	//The LOCAL_BURST_LEN_s is a signal used insted of the parameter LOCAL_BURST_LEN
	assign LOCAL_BURST_LEN_s = 2;

	assign local_burstbegin = burst_begin;
	assign local_cs_addr = cs_addr;
	assign local_row_addr = row_addr;
	assign local_bank_addr = bank_addr;
	assign local_col_addr = col_addr;
	assign local_write_req = write_req;
	assign local_wdata = to_ddr2_data;
	assign local_read_req = read_req;
	assign local_be = {4{1'b1}};
	assign local_size = size;
	assign size = (full_burst_on == 0)? 1'd1 : LOCAL_BURST_LEN_s[2:0];

	always @(posedge clk)
		from_ddr2_data <= local_rdata;
		
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			from_ddr2_data_valid <= 1'b0;
		else
			from_ddr2_data_valid <= local_rdata_valid;
 
	//-----------------------------------------------------------------
	//Read / Write control state machine & address counter
	//-----------------------------------------------------------------
	always @(posedge clk or negedge rst_n)
    begin
		if(!rst_n)
        begin
			//Reset - asynchronously force all register outputs LOW
			state 			<= IDLE;
			reset_address 	<= 1'b0;
			burst_begin 	<= 1'b0;
			write_req		<= 1'b0;
			read_req		<= 1'b0;
			full_burst_on 	<= 1'b0;
			wr_rd_hit		<= 1'b0;
		end
		else
		begin
			case(state)
			IDLE:
			begin
				reset_address <= 1'b0;
				if(to_ddr2_strb)
				begin
					full_burst_on <= 1'b0;
					state <= WRITE;
				end
				else if(from_ddr2_strb)
				begin
					burst_begin <= 1'b1;
					read_req <= 1'b1;
					full_burst_on <= 1'b1;
					state <= READ;
				end
			end
  
			WRITE: 
			begin
				wr_rd_hit		<= 1'b1; //	wr_rd_hit = 1, write to ddr2
				if(reached_buf_tail)
				begin
					write_req <= 1'b0;
                    state <= IDLE; 
				end
				else if(to_ddr2_req)
					write_req <= 1'b1;
                else if(write_req & local_ready)
				begin
					if(reached_max_address)
                    begin
						reset_address <= 1'b1;
						write_req <= 1'b0;
                        state <= IDLE; 
					end
					else
					begin
						burst_begin <= 1'b1;
						write_req <= 1'b0;
					end
				end
				else
				begin
					burst_begin <= 1'b0;
					write_req <= 1'b0;
				end
			end
			
			READ:
			begin
				wr_rd_hit		<= 1'b0; //	wr_rd_hit = 0, read from ddr2
				if(!local_ready)
                begin
					read_req <= 1'b1;
                    burst_begin <= 1'b0;
                end
                else if(local_ready & read_req)
				begin
					if (reached_max_address | reached_max_hcnt)
                    begin
						read_req <= 1'b0;
                        burst_begin <= 1'b0;
                        state <= 5'd8;
                     end
                     else 
                     begin
						read_req <= 1'b1;
                        burst_begin <= 1'b1;
                     end
				end
			end
			endcase
		end
	end

	//-----------------------------------------------------------------
	//Address Generator Process
	//-----------------------------------------------------------------
	always @(posedge clk or negedge rst_n)
    begin
		if(!rst_n)
        begin
			cs_addr <= 0;
			bank_addr <= 0;
			row_addr <= 0;
			col_addr <= 0;
        end
		else if(reset_address)
        begin
			cs_addr <= MIN_CHIPSEL;
			row_addr <= 0;
			bank_addr <= 0;
			col_addr <= 0;
        end
		else if((local_ready & write_req) | (local_ready & read_req ))
		begin
			if(col_addr >= max_col_value)
            begin
				col_addr <= 0;
				if(row_addr == MAX_ROW)
                begin
					row_addr <= 0;
					if(bank_addr == MAX_BANK)
                    begin
						bank_addr <= 0;
						if(cs_addr == MAX_CHIPSEL)
							cs_addr <= MIN_CHIPSEL;
						else 
							cs_addr <= cs_addr + 1'b1;
                    end
					else 
						bank_addr <= bank_addr + 1'b1;
                end
				else 
					row_addr <= row_addr + 1'b1;
			end
			else 
				col_addr <= col_addr + addr_value;
		end
	end

	
	always @(posedge clk or negedge rst_n)
		if(!rst_n)	
			h_cnt <= 10'd0;
		else if(reached_max_hcnt)
			h_cnt <= 10'd0;
		else if((wr_rd_hit & local_ready & write_req) | (~wr_rd_hit & local_rdata_valid))
			h_cnt <= h_cnt + 1'b1;

	always @(posedge clk or negedge rst_n)
		if(!rst_n)	
			v_cnt <= 10'd0;
		else if(reached_buf_tail)
			v_cnt <= 10'd0;
		else if(reached_max_hcnt)
			v_cnt <= v_cnt + 1'b1;			
	
endmodule	
