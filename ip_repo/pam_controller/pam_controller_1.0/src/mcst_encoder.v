`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/19/2023 10:06:15 AM
// Design Name: 
// Module Name: mcst_encoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mcst_encoder(
    input i_clk,          // Clock signal
    input i_clk2x,         // fast clock
    input i_enable,       // enable signal 
    input i_data_in,      // Input binary data
    output reg o_enc_out  // Manchester encoded output
);

wire enc_data;

initial begin
    o_enc_out <= 1'b0;
end

always @(posedge i_clk2x) begin
     if (i_enable == 1'b1) begin
        o_enc_out <= ~(i_clk ^ i_data_in);
     end else begin
        o_enc_out <= 1'b0;
     end
end

endmodule
