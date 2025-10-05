module Real_Add #(
    parameter DATA_WIDTH = 16,
    parameter DELAY = 0
) (
    input clk,
    input rst,
    input  signed [DATA_WIDTH-1:0] I1,
    input  signed [DATA_WIDTH-1:0] I2,
    output signed [DATA_WIDTH  :0] Io
);

    wire signed [DATA_WIDTH:0] Io_;

    assign Io_ = I1 + I2;

    generate
        if (DELAY) begin
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH+1)) D_I (
                .clk(clk),
                .rst(rst),
                .in(Io_),
                .out(Io)
            );
        end
        else begin
            assign Io = Io_;
        end
    endgenerate

endmodule
