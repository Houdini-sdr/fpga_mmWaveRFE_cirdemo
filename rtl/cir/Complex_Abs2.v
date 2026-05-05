module Complex_Abs2 #(
    parameter I_WIDTH = 8,
    parameter O_WIDTH = 16,
    parameter DELAY = 0
) (
    input clk,
    input rst,
    input  signed [I_WIDTH-1:0] I,
    input  signed [I_WIDTH-1:0] Q,
    output signed [O_WIDTH-1:0] O
);

    wire signed [O_WIDTH-1:0] I2, I2_, Q2, Q2_, O_;

    assign I2_ = I * I;
    assign Q2_ = Q * Q;

    generate
        if (DELAY >= 2) begin
            assign O_ = I2 + Q2;
            Delay_1 #(.DATA_WIDTH(O_WIDTH)) D_I (
                .clk(clk),
                .rst(rst),
                .in(I2_),
                .out(I2)
            );
            Delay_1 #(.DATA_WIDTH(O_WIDTH)) D_Q (
                .clk(clk),
                .rst(rst),
                .in(Q2_),
                .out(Q2)
            );
            Delay_n #(.DELAY(DELAY-1), .DATA_WIDTH(O_WIDTH)) D_O (
                .clk(clk),
                .rst(rst),
                .in(O_),
                .out(O)
            );
        end
        else if (DELAY == 1) begin
            assign O_ = I2_ + Q2_;
            Delay_1 #(.DATA_WIDTH(O_WIDTH)) D_O (
                .clk(clk),
                .rst(rst),
                .in(O_),
                .out(O)
            );
        end
        else begin
            assign O = I2_ + Q2_;
        end
    endgenerate

endmodule
