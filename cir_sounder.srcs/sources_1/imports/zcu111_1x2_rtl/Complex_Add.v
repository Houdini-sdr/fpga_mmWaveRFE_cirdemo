module Complex_Add #(
    parameter DATA_WIDTH = 16,
    parameter DELAY = 0
) (
    input clk,
    input rst,
    input  signed [DATA_WIDTH-1:0] I1,
    input  signed [DATA_WIDTH-1:0] Q1,
    input  signed [DATA_WIDTH-1:0] I2,
    input  signed [DATA_WIDTH-1:0] Q2, // <-- decided by CONJ
    output signed [DATA_WIDTH  :0] Io,
    output signed [DATA_WIDTH  :0] Qo
);

    wire signed [DATA_WIDTH:0] Io_, Qo_;

    assign Io_ = I1 + I2;
    assign Qo_ = Q1 + Q2;

    generate
        if (DELAY) begin
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH+1)) D_I (
                .clk(clk),
                .rst(rst),
                .in(Io_),
                .out(Io)
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH+1)) D_Q (
                .clk(clk),
                .rst(rst),
                .in(Qo_),
                .out(Qo)
            );
        end
        else begin
            assign Io = Io_;
            assign Qo = Qo_;
        end
    endgenerate

endmodule
