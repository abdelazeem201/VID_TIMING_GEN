`timescale 1ns/10ps
module video_tim (
	input 				clk, 	// master clock
	input 				rst_n, 	// synchronous active low reset
	input 				ena, 	// count enable
	input	[7:0] 		Tsync, 	// sync duration
	input 	[7:0] 		Tgdel, 	// gate delay
	input 	[15:0] 		Tgate, 	// gate length
	input 	[15:0] 		Tlen,  	// line time/frame time
	output 	reg 		sync, 	// synchronization pulse
	output 	reg			gate, 	// gate
	output 	reg			done 	// done with line/frame
);

	// generate timing state machine
	reg  	[15:0] 		cnt, cnt_len;
	wire 	[16:0] 		cnt_nxt, cnt_len_nxt;
	wire        		cnt_done, cnt_len_done;
	
	reg 	[4:0] 		state;
	localparam 			IDLE_S = 5'b00001;
	localparam 			SYNC_S = 5'b00010;
	localparam 			GDEL_S = 5'b00100;
	localparam 			GATE_S = 5'b01000;
	localparam 			LEN_S  = 5'b10000;

	assign cnt_nxt 		= {1'b0, cnt} - 1'b1;
	assign cnt_done 	= cnt_nxt[16];

	assign cnt_len_nxt 	= {1'b0, cnt_len} - 1'b1;
	assign cnt_len_done = cnt_len_nxt[16];

	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
	        state   <= IDLE_S;
	        cnt     <= 16'h0;
	        cnt_len <= 16'b0;
	        sync    <= 1'b0;
	        gate    <= 1'b0;
	        done    <= 1'b0;
	    end
		else if (ena)
	    begin
			cnt     <= cnt_nxt[15:0];
	        cnt_len <= cnt_len_nxt[15:0];
	        done    <= 1'b0;

	        case (state) // synopsys full_case parallel_case
	        IDLE_S:
	        begin
				state   <= SYNC_S;
				cnt     <= Tsync;
				cnt_len <= Tlen;

				sync    <= 1'b1;
	        end

			SYNC_S:
			begin
				if (cnt_done)
				begin
					state <= GDEL_S;
					cnt   <= Tgdel;

					sync  <= 1'b0;
				end
			end

			GDEL_S:
			begin
				if (cnt_done)
				begin
					state <= GATE_S;
					cnt   <= Tgate;

					gate  <= 1'b1;
	            end
			end

			GATE_S:
			begin
	            if (cnt_done)
				begin
					state <= LEN_S;

					gate  <= 1'b0;
	             end
			end

			LEN_S:
			begin
	            if (cnt_len_done)
				begin
					state   <= SYNC_S;
					cnt     <= Tsync;
					cnt_len <= Tlen;

					sync    <= 1'b1;
	                done    <= 1'b1;
				end
			end
	        endcase
	    end
	end
		
endmodule
