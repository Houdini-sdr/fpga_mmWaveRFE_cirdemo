`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2024 06:08:28 PM
// Design Name: 
// Module Name: delay
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


module delay #(
    parameter DELAY_CYCLES = 10  // Number of cycles to delay
)(
    input clk,
    input rst,
    input in_signal,
    output reg out_signal
);

    // Shift register for delaying the signal
    reg [DELAY_CYCLES-1:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all elements in the shift register and output signal
            shift_reg <= 0;
            out_signal <= 0;
        end else begin
            // Shift the register and update the output signal
            shift_reg <= {shift_reg[DELAY_CYCLES-2:0], in_signal};
            out_signal <= shift_reg[DELAY_CYCLES-1];
        end
    end

endmodule
