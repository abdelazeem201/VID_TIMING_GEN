/////////////////////////////////////////////////////////////////////
// video_tim Module
// Author: Ahmed Abdelazeem
// Description: Verilog module for generating timing signals based
// on a state machine. It generates synchronization pulses, gate
// signals, and signals when a line/frame is done based on input
// parameters.
/////////////////////////////////////////////////////////////////////

module video_tim (
    input 				clk,   // Master clock
    input 				rst_n, // Synchronous active-low reset
    input 				ena,   // Count enable
    input	[7:0] 		Tsync, // Sync duration
    input 	[7:0] 		Tgdel, // Gate delay
    input 	[15:0] 		Tgate, // Gate length
    input 	[15:0] 		Tlen,  // Line time/frame time
    output 	reg 		sync,  // Synchronization pulse
    output 	reg			gate,  // Gate
    output 	reg			done   // Done with line/frame
);

    // Generate timing state machine
    reg  	[15:0] 		cnt, cnt_len;
    wire 	[16:0] 		cnt_nxt, cnt_len_nxt;
    wire        		cnt_done, cnt_len_done;

    reg 	[4:0] 		state;
    localparam 			IDLE_S = 5'b00001;
    localparam 			SYNC_S = 5'b00010;
    localparam 			GDEL_S = 5'b00100;
    localparam 			GATE_S = 5'b01000;
    localparam 			LEN_S  = 5'b10000;

    // Calculate next counter values and check if the counters are done
    assign cnt_nxt 		= {1'b0, cnt} - 1'b1;
    assign cnt_done 	= cnt_nxt[16];

    assign cnt_len_nxt 	= {1'b0, cnt_len} - 1'b1;
    assign cnt_len_done = cnt_len_nxt[16];

    // State machine logic
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

            case (state)
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
