module Complex_Mul #(
    parameter I_WIDTH = 8,
    parameter O_WIDTH = 16,
    parameter CONJ = 0,
    parameter DELAY = 0
) (
    input en,
    input clk,
    input rst,
    input  signed [I_WIDTH-1:0] I1,
    input  signed [I_WIDTH-1:0] Q1,
    input  signed [I_WIDTH-1:0] I2,
    input  signed [I_WIDTH-1:0] Q2, // <-- decided by CONJ
    output signed [O_WIDTH-1:0] Io,
    output signed [O_WIDTH-1:0] Qo
);

    wire signed [O_WIDTH-1:0] S1, S2, S3, S1_, S2_, S3_, Io_, Qo_;
    wire signed [I_WIDTH:0] t1, t2, t3, t1_, t2_, t3_;
    wire signed [I_WIDTH-1:0] a, b, c, d, a_, b_, c_;

    assign a_ = I1;
    assign b_ = Q1;
    assign c_ = I2;
    assign d = Q2; // <-- decided by CONJ

    generate
        if (DELAY >= 2) begin
            Delay_1 #(.DATA_WIDTH(I_WIDTH)) D_a (
                .clk(clk),
                .rst(rst),
                .in(a_),
                .out(a)
            );
            Delay_1 #(.DATA_WIDTH(I_WIDTH)) D_b (
                .clk(clk),
                .rst(rst),
                .in(b_),
                .out(b)
            );
            Delay_1 #(.DATA_WIDTH(I_WIDTH)) D_c (
                .clk(clk),
                .rst(rst),
                .in(c_),
                .out(c)
            );
            Delay_1 #(.DATA_WIDTH(I_WIDTH+1)) D_t1 (
                .clk(clk),
                .rst(rst),
                .in(t1_),
                .out(t1)
            );
            Delay_1 #(.DATA_WIDTH(I_WIDTH+1)) D_t2 (
                .clk(clk),
                .rst(rst),
                .in(t2_),
                .out(t2)
            );
            Delay_1 #(.DATA_WIDTH(I_WIDTH+1)) D_t3 (
                .clk(clk),
                .rst(rst),
                .in(t3_),
                .out(t3)
            );
        end
        else begin
            assign t1 = t1_;
            assign t2 = t2_;
            assign t3 = t3_;
            assign a = a_;
            assign b = b_;
            assign c = c_;
        end
    endgenerate

    if (DELAY >= 3) begin
        reg signed [O_WIDTH-1:0] M1[0:DELAY-3], M2[0:DELAY-3], M3[0:DELAY-3];
        integer i;
        always@(posedge clk) begin
            M1[0] <= c * t1;
            M2[0] <= a * t2;
            M3[0] <= b * t3;
            for (i = 0; i < DELAY-3; i = i+1) begin
                M1[i+1] <= M1[i];
                M2[i+1] <= M2[i];
                M3[i+1] <= M3[i];
            end
        end
        assign S1 = M1[DELAY-3];
        assign S2 = M2[DELAY-3];
        assign S3 = M3[DELAY-3];
    end
    else begin
        assign S1 = c * t1;
        assign S2 = a * t2;
        assign S3 = b * t3;
    end

    assign t1_ = a_ + b_;
    generate
        if (CONJ == 0) begin
            assign t2_ = d - c_;
            assign t3_ = c_ + d;
        end
        else begin
            assign t2_ = c_ + d;
            assign t3_ = d - c_;
        end
    endgenerate

    generate
        if (CONJ == 0) begin
            assign Io_ = S1 - S3;
            assign Qo_ = S1 + S2;
        end
        else begin
            assign Io_ = S1 + S3;
            assign Qo_ = S1 - S2;
        end
    endgenerate

    generate
        if (DELAY) begin
            Delay_1 #(.DATA_WIDTH(O_WIDTH)) D_I (
                .clk(clk),
                .rst(rst),
                .in(Io_),
                .out(Io)
            );
            Delay_1 #(.DATA_WIDTH(O_WIDTH)) D_Q (
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
