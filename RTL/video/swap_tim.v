`timescale 1ns/10ps
module swap_tim (
    input 			clk,
	input			rst_n,
	input			ena,
	input			buf_swap,
	input 	[ 7:0] 	Thsync,
	input 	[ 7:0] 	Tgdel, 	// gate delay
	input 	[15:0] 	Tgate, 	// gate length	
	input 	[15:0] 	Thlen, 
	output	reg		hsync,
	output	reg		vsync,
	output	reg		daten
);
	
	wire			swap;
	reg  			swap_d;
	wire			swap_posedge;
	reg				swap_latch;
	// generate timing state machine
	reg		[15:0]	cnt_dur, cnt_len;
	wire 	[16:0] 	cnt_dur_nxt, cnt_len_nxt;
	wire        	cnt_dur_done, cnt_len_done;
	reg		[2:0]	cnt_hsync;
	reg 			done;
	reg				sync;
	reg 			gate;
	
	localparam		Thsynccnt = 4;
	
	reg 	[4:0] 	state;
	localparam 			IDLE_S = 5'b00001;
	localparam 			SYNC_S = 5'b00010;
	localparam 			GDEL_S = 5'b00100;
	localparam 			GATE_S = 5'b01000;
	localparam 			LEN_S  = 5'b10000;
	
	assign cnt_dur_nxt 	= {1'b0, cnt_dur} - 1'b1;
	assign cnt_dur_done = cnt_dur_nxt[16];

	assign cnt_len_nxt 	= {1'b0, cnt_len} - 1'b1;
	assign cnt_len_done = cnt_len_nxt[16];
	
	signal_cross_domain #(
		.DEFAULT(1'b0)) 
	INST_CROSS_DOMAIN (
		.clkb(clk),
		.rst_n(rst_n),
		.signal_in_clka(buf_swap),
		.signal_out_clkb(swap)
	);
	
	// swap signal posedge
	assign swap_posedge = swap & !swap_d;
	
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			swap_d <= 1'b0;
		else
			swap_d <= swap;
			
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			swap_latch <= 1'b0;
		else if(swap_posedge)
			swap_latch <= 1'b1;
		else if(ena)
			swap_latch <= 1'b0;
		
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
	        state   <= IDLE_S;
	        cnt_dur <= 16'h0;
	        cnt_len <= 16'b0;
	        sync    <= 1'b0;
			gate	<= 1'b0;
	        done    <= 1'b0;
	    end
		else if(ena)
	    begin
			cnt_dur <= cnt_dur_nxt[15:0];
	        cnt_len <= cnt_len_nxt[15:0];
	        done    <= 1'b0;

	        case(state) // synopsys full_case parallel_case
	        IDLE_S:
	        begin
				if(swap_latch)
				begin
					state   <= SYNC_S;
					cnt_dur <= Thsync;
					cnt_len <= Thlen;

					sync    <= 1'b1;
				end
	        end

			SYNC_S:
			begin
				if(cnt_dur_done)
				begin
					state 	<= GDEL_S;
					cnt_dur	<= Tgdel;

					sync  	<= 1'b0;
				end
			end
			
			GDEL_S:
			begin
				if (cnt_dur_done)
				begin
					state 	<= GATE_S;
					cnt_dur <= Tgate;

					gate  	<= 1'b1;
	            end
			end

			GATE_S:
			begin
	            if (cnt_dur_done)
				begin
					state <= LEN_S;

					gate  <= 1'b0;
	             end
			end

			LEN_S:
			begin
				if(~|cnt_hsync)
					state   <= IDLE_S;
	            else if(cnt_len_done)
				begin
					state   <= SYNC_S;
					cnt_dur <= Thsync;
					cnt_len <= Thlen;

					sync    <= 1'b1;
	                done    <= 1'b1;
				end
			end
	        endcase
	    end
	end
	

	// hsync counter
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			cnt_hsync <= 3'd0;
		else if(swap_posedge)
			cnt_hsync <= Thsynccnt;
		else if(ena & done)
			cnt_hsync <= cnt_hsync - 1'b1;

				// vsync output for trigger
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			hsync <= 1'b0;
		else
			hsync <= sync;	
			
	// vsync output for trigger
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			vsync <= 1'b0;
		else if(done & (cnt_hsync == Thsynccnt-2))
			vsync <= 1'b1;	
		else if(done & (cnt_hsync == Thsynccnt-3))
			vsync <= 1'b0;		
	
	// data enable output for trigger
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			daten <= 1'b0;
		else
			daten <= gate & ((cnt_hsync == Thsynccnt) | (cnt_hsync == Thsynccnt-1));
	
endmodule
