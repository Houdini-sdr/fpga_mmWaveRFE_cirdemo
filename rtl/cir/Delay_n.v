module Delay_n #(
    parameter DELAY      = 1,
    parameter DATA_WIDTH = 1
) (
    input                   clk,
    input                   rst,
    input  signed [DATA_WIDTH-1:0] in,
    output signed [DATA_WIDTH-1:0] out
);

    genvar i;
    generate
        if (DELAY == 0) begin
            assign out = in;
        end
        else if (DELAY == 1) begin
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) D1 (.clk(clk), .rst(rst), .in(in), .out(out));
        end
        else if (DELAY > 1) begin
            wire [DATA_WIDTH-1:0] tmp[0:DELAY];
            assign tmp[0] = in;
            for (i = 1; i <= DELAY; i = i+1) begin: DELAY_G1
                Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) D (.clk(clk), .rst(rst), .in(tmp[i-1]), .out(tmp[i]));
            end
            assign out = tmp[DELAY];
        end
    endgenerate

endmodule
