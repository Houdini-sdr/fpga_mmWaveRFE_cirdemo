module CIR_Rotate #(
    parameter DATA_WIDTH = 16
) (
    input signed [DATA_WIDTH-1:0] I1,
    input signed [DATA_WIDTH-1:0] I2,
    input signed [DATA_WIDTH-1:0] I3,
    input signed [DATA_WIDTH-1:0] I4,
    input signed [DATA_WIDTH-1:0] I5,
    input signed [DATA_WIDTH-1:0] I6,
    input signed [DATA_WIDTH-1:0] I7,
    input signed [DATA_WIDTH-1:0] I8,
    input signed [DATA_WIDTH-1:0] Q1,
    input signed [DATA_WIDTH-1:0] Q2,
    input signed [DATA_WIDTH-1:0] Q3,
    input signed [DATA_WIDTH-1:0] Q4,
    input signed [DATA_WIDTH-1:0] Q5,
    input signed [DATA_WIDTH-1:0] Q6,
    input signed [DATA_WIDTH-1:0] Q7,
    input signed [DATA_WIDTH-1:0] Q8,
    output       [DATA_WIDTH*8-1:0] I,
    output       [DATA_WIDTH*8-1:0] Q
);

    wire signed [DATA_WIDTH-1:0] I1_o, I2_o, I3_o, I4_o, I5_o, I6_o, I7_o, I8_o;
    wire signed [DATA_WIDTH-1:0] Q1_o, Q2_o, Q3_o, Q4_o, Q5_o, Q6_o, Q7_o, Q8_o;

    assign I = { I8_o, I7_o, I6_o, I5_o, I4_o, I3_o, I2_o, I1_o };
    assign Q = { Q8_o, Q7_o, Q6_o, Q5_o, Q4_o, Q3_o, Q2_o, Q1_o };

    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_1 (
        .ang(2'b00),
        .I_i(I1),
        .Q_i(Q1),
        .I_o(I1_o),
        .Q_o(Q1_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_2 (
        .ang(2'b11),
        .I_i(I2),
        .Q_i(Q2),
        .I_o(I2_o),
        .Q_o(Q2_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_3 (
        .ang(2'b10),
        .I_i(I3),
        .Q_i(Q3),
        .I_o(I3_o),
        .Q_o(Q3_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_4 (
        .ang(2'b01),
        .I_i(I4),
        .Q_i(Q4),
        .I_o(I4_o),
        .Q_o(Q4_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_5 (
        .ang(2'b00),
        .I_i(I5),
        .Q_i(Q5),
        .I_o(I5_o),
        .Q_o(Q5_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_6 (
        .ang(2'b11),
        .I_i(I6),
        .Q_i(Q6),
        .I_o(I6_o),
        .Q_o(Q6_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_7 (
        .ang(2'b10),
        .I_i(I7),
        .Q_i(Q7),
        .I_o(I7_o),
        .Q_o(Q7_o)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_8 (
        .ang(2'b01),
        .I_i(I8),
        .Q_i(Q8),
        .I_o(I8_o),
        .Q_o(Q8_o)
    );

endmodule
