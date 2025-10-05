module Delay_1 #(
    parameter DATA_WIDTH = 1
) (
    input                       clk,
    input                       rst,
    input  signed     [DATA_WIDTH-1:0] in,
    output reg signed [DATA_WIDTH-1:0] out
);

    always @(posedge clk, posedge rst) begin
        if (rst) out <= 0;
        else out <= in;
    end

endmodule
