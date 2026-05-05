module GACE_top #(
    DATA_WIDTH = 16
)(
    input  clk,
    input  rst,
    input  en,
    input  signed [DATA_WIDTH-1:0] I1,
    input  signed [DATA_WIDTH-1:0] I2,
    input  signed [DATA_WIDTH-1:0] I3,
    input  signed [DATA_WIDTH-1:0] I4,
    input  signed [DATA_WIDTH-1:0] I5,
    input  signed [DATA_WIDTH-1:0] I6,
    input  signed [DATA_WIDTH-1:0] I7,
    input  signed [DATA_WIDTH-1:0] I8,
    input  signed [DATA_WIDTH-1:0] Q1,
    input  signed [DATA_WIDTH-1:0] Q2,
    input  signed [DATA_WIDTH-1:0] Q3,
    input  signed [DATA_WIDTH-1:0] Q4,
    input  signed [DATA_WIDTH-1:0] Q5,
    input  signed [DATA_WIDTH-1:0] Q6,
    input  signed [DATA_WIDTH-1:0] Q7,
    input  signed [DATA_WIDTH-1:0] Q8,
    input  [3:0] cnt_init,
    output [DATA_WIDTH*8-1:0] CIR_I,
    output [DATA_WIDTH*8-1:0] CIR_Q,
    output start,
    output last     // Kai, 2024-5
);

    wire [DATA_WIDTH-1:0] OI1, OI2, OI3, OI4, OI5, OI6, OI7, OI8;
    wire [DATA_WIDTH-1:0] OQ1, OQ2, OQ3, OQ4, OQ5, OQ6, OQ7, OQ8;

    Real_CIR_Est CIR_Est_I(
        .clk(clk),
        .rst(rst),
        .en(en),
        .cnt_init(cnt_init),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I5(I5),
        .I6(I6),
        .I7(I7),
        .I8(I8),
        .O1(OI1),
        .O2(OI2),
        .O3(OI3),
        .O4(OI4),
        .O5(OI5),
        .O6(OI6),
        .O7(OI7),
        .O8(OI8),
        .start(start),
        .last(last)     // Kai, 2024-5
    );

    Real_CIR_Est CIR_Est_Q(
        .clk(clk),
        .rst(rst),
        .en(en),
        .cnt_init(cnt_init),
        .I1(Q1),
        .I2(Q2),
        .I3(Q3),
        .I4(Q4),
        .I5(Q5),
        .I6(Q6),
        .I7(Q7),
        .I8(Q8),
        .O1(OQ1),
        .O2(OQ2),
        .O3(OQ3),
        .O4(OQ4),
        .O5(OQ5),
        .O6(OQ6),
        .O7(OQ7),
        .O8(OQ8),
        .start(),
        .last()     // Kai, 2024-5
    );
    
    assign CIR_I = { OI8, OI7, OI6, OI5, OI4, OI3, OI2, OI1 };
    assign CIR_Q = { OQ8, OQ7, OQ6, OQ5, OQ4, OQ3, OQ2, OQ1 };

//    CIR_Rotate CIR_rot (
//        .I1(OI1),
//        .I2(OI2),
//        .I3(OI3),
//        .I4(OI4),
//        .I5(OI5),
//        .I6(OI6),
//        .I7(OI7),
//        .I8(OI8),
//        .Q1(OQ1),
//        .Q2(OQ2),
//        .Q3(OQ3),
//        .Q4(OQ4),
//        .Q5(OQ5),
//        .Q6(OQ6),
//        .Q7(OQ7),
//        .Q8(OQ8),
//        .I(CIR_I),
//        .Q(CIR_Q)
//    );

endmodule
