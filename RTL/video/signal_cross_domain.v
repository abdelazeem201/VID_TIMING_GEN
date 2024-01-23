/////////////////////////////////////////////////////////////////////
// signal_cross_domain Module
// Author: Ahmed Abdelazeem
// Description: Verilog module to synchronize a signal from one
// clock domain (clka) to another clock domain (clkb).
/////////////////////////////////////////////////////////////////////

module signal_cross_domain #(
    parameter DEFAULT = 1'b0  // Default value for the synchronized signal when in reset
)(
    input clkb,              // Clock input for the clkb clock domain
    input rst_n,             // Active-low asynchronous reset signal
    input signal_in_clka,    // Input signal from clka clock domain to be synchronized
    output signal_out_clkb   // Synchronized output signal for clkb clock domain
);

    reg [3:0] synca_clkb;  // 4-bit shift register to synchronize signal_in_clka to clkb clock domain

    // Synchronization process using a two-stage shift register
    always @(posedge clkb or negedge rst_n)
        if (!rst_n)
            synca_clkb[0] <= DEFAULT;  // Reset the first stage to the default value
        else
            synca_clkb[0] <= signal_in_clka;  // Capture the input signal on the rising edge of clkb

    always @(posedge clkb)
        if (!rst_n)
            synca_clkb[1] <= DEFAULT;  // Reset the second stage to the default value
        else
            synca_clkb[1] <= synca_clkb[0];  // Shift the value from the first stage to the second stage

    always @(posedge clkb)
        if (!rst_n)
            synca_clkb[2] <= DEFAULT;  // Reset the third stage to the default value
        else
            synca_clkb[2] <= synca_clkb[1];  // Shift the value from the second stage to the third stage

    always @(posedge clkb)
        if (!rst_n)
            synca_clkb[3] <= DEFAULT;  // Reset the fourth stage to the default value
        else
            synca_clkb[3] <= synca_clkb[2];  // Shift the value from the third stage to the fourth stage

    assign signal_out_clkb = synca_clkb[3];  // Output the synchronized signal from the fourth stage

endmodule
