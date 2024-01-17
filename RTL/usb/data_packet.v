////////////////////////////////////////////////////////////////////////////////
// Module: data_packet
// Description: Verilog module for assembling a 24-bit data packet from a
//              stream of 8-bit data bytes. The module includes a byte counter
//              to keep track of the byte being processed and generate a valid
//              signal when a complete packet is formed.
// Designer: Ahmed Abdelazeem
////////////////////////////////////////////////////////////////////////////////

module data_packet (
	input				clk,
	input				rst_n,
	input		[7:0]	data_byte,
	input				data_byte_valid,
	output	reg [23:0]	pack_data,
	output	reg 		pack_data_valid
);

	reg		[1:0]	byte_cnt;
	
	// Byte counter logic
	always @ (posedge clk or negedge rst_n)
		if(!rst_n)
			byte_cnt <= 2'b00;
		else if(byte_cnt[1])
			byte_cnt <= 2'b00;
		else if(data_byte_valid)
			byte_cnt <= byte_cnt + 1'b1;

	// Data packing logic
	always @ (posedge clk)
		case(byte_cnt)
			0: pack_data[7:0] 	<= data_byte;
			1: pack_data[23:16] <= data_byte;
			2: pack_data[15:8]	<= data_byte;
			default pack_data 	<= 24'd0;
		endcase

	// Packet valid signal generation
	always @ (posedge clk or negedge rst_n)
		if(!rst_n)		
			pack_data_valid <= 1'b0;
		else if(byte_cnt[1] && data_byte_valid)
			pack_data_valid <= 1'b1;
		else	
			pack_data_valid <= 1'b0;
			
endmodule
