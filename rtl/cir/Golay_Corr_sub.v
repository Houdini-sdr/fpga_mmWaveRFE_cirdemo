/**
 * Module     : Golay_Corr_Sub
 * Description: Golay-sequence correlation sub structure.
 * Author     : Wuqiong Zhao (me@wqzhao.org)
 *
 * Created    : 2023-05-31
 *
 */

module Golay_Corr_Sub #(
    parameter DATA_WIDTH = 16,
    parameter DELAY      = 1,
    parameter WEIGHT     = 1,
    parameter HALF       = 1
) (
    input                   clk,
    input                   rst,
    input                   en,
    input  signed [DATA_WIDTH-1:0] Ia,
    input  signed [DATA_WIDTH-1:0] Ib,
    output signed [DATA_WIDTH-1:0] Oa,
    output signed [DATA_WIDTH-1:0] Ob
);

    wire signed [DATA_WIDTH-1:0] Ib_nD; // Ib with delay
    wire signed [DATA_WIDTH-1:0] sum, sub;

    assign sum = Ia + Ib_nD;
    assign sub = Ia - Ib_nD;

    generate
        if (HALF == 0) begin
            if (WEIGHT == 1) begin: weight_1
                assign Oa = sum;
                assign Ob = sub;
            end
            else begin: weight_0
                assign Oa = sub;
                assign Ob = sum;
            end
        end
        else begin
            if (WEIGHT == 1) begin: weight_1
                assign Oa = sum >>> 1;
                assign Ob = sub >>> 1;
            end
            else begin: weight_0
                assign Oa = sub >>> 1;
                assign Ob = sum >>> 1;
            end
        end
    endgenerate

    Delay_n #(.DELAY(DELAY), .DATA_WIDTH(DATA_WIDTH)) D (
        .clk(clk),
        .rst(rst),
        .in(Ib),
        .out(Ib_nD)
    );

endmodule
