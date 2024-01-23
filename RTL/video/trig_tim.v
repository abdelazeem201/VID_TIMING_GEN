/////////////////////////////////////////////////////////////////////
// trig_tim Module
// Author: Ahmed Abdelazeem
// Description: Verilog module for generating timing signals for
// horizontal and vertical synchronization based on a state machine.
// The module includes a counter for horizontal synchronization,
// generates sync pulses, and outputs data enable signal.
/////////////////////////////////////////////////////////////////////

module trig_tim (
    input 			clk,        // Master clock
    input			rst_n,      // Active-low asynchronous reset
    input			ena,        // Count enable
    input			trig,       // Trigger input
    input 	[ 7:0] 	Thsync,     // Horizontal sync pulse width (in pixels)
    input 	[15:0] 	Thlen,      // Horizontal length (number of pixels per line)
    output	reg		hsync,      // Horizontal sync pulse
    output	reg		vsync,      // Vertical sync pulse
    output			daten       // Data enable signal
);

    // Variable declarations
    reg [15:0] cnt_dur, cnt_len;
    wire [16:0] cnt_dur_nxt, cnt_len_nxt;
    wire        cnt_dur_done, cnt_len_done;
    reg [2:0]  cnt_hsync;
    reg        done;
    reg        trig_latch;
    reg        sync;

    localparam Thsynccnt = 3;

    reg [2:0]  state;
    localparam IDLE_S = 3'b001;
    localparam SYNC_S = 3'b010;
    localparam LEN_S  = 3'b100;

    // Calculate next counter values and check if the counters are done
    assign cnt_dur_nxt  = {1'b0, cnt_dur} - 1'b1;
    assign cnt_dur_done = cnt_dur_nxt[16];

    assign cnt_len_nxt  = {1'b0, cnt_len} - 1'b1;
    assign cnt_len_done = cnt_len_nxt[16];

    // Trigger latch logic
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            trig_latch <= 1'b0;
        else if (trig)
            trig_latch <= 1'b1;
        else if (ena)
            trig_latch <= 1'b0;

    // State machine logic for timing generation
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state   <= IDLE_S;
            cnt_dur <= 16'h0;
            cnt_len <= 16'b0;
            sync    <= 1'b0;
            done    <= 1'b0;
        end
        else if (ena)
        begin
            cnt_dur <= cnt_dur_nxt[15:0];
            cnt_len <= cnt_len_nxt[15:0];
            done    <= 1'b0;

            case(state)
                IDLE_S:
                begin
                    if (trig_latch)
                    begin
                        state   <= SYNC_S;
                        cnt_dur <= Thsync;
                        cnt_len <= Thlen;

                        sync    <= 1'b1;
                    end
                end

                SYNC_S:
                begin
                    if (cnt_dur_done)
                    begin
                        state <= LEN_S;
                        sync  <= 1'b0;
                    end
                end

                LEN_S:
                begin
                    if (~|cnt_hsync)
                        state   <= IDLE_S;
                    else if (cnt_len_done)
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

    // Counter for hsync
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            cnt_hsync <= 3'd0;
        else if (trig)
            cnt_hsync <= Thsynccnt;
        else if (ena & done)
            cnt_hsync <= cnt_hsync - 1'b1;

    // Output signals
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            hsync <= 1'b0;
        else
            hsync <= sync;

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            vsync <= 1'b0;
        else if (done & (cnt_hsync == Thsynccnt))
            vsync <= 1'b1;
        else if (done & (cnt_hsync == Thsynccnt-1))
            vsync <= 1'b0;

    // Data enable output for trigger
    assign daten = 1'b0;

endmodule
