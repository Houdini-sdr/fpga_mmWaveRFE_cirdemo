module Derotate_p8 #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT = 4
) (
    input  [DATA_WIDTH*8-1:0] I,
    input  [DATA_WIDTH*8-1:0] Q,
    output signed [DATA_WIDTH-1:0] I1,
    output signed [DATA_WIDTH-1:0] I2,
    output signed [DATA_WIDTH-1:0] I3,
    output signed [DATA_WIDTH-1:0] I4,
    output signed [DATA_WIDTH-1:0] I5,
    output signed [DATA_WIDTH-1:0] I6,
    output signed [DATA_WIDTH-1:0] I7,
    output signed [DATA_WIDTH-1:0] I8,
    output signed [DATA_WIDTH-1:0] Q1,
    output signed [DATA_WIDTH-1:0] Q2,
    output signed [DATA_WIDTH-1:0] Q3,
    output signed [DATA_WIDTH-1:0] Q4,
    output signed [DATA_WIDTH-1:0] Q5,
    output signed [DATA_WIDTH-1:0] Q6,
    output signed [DATA_WIDTH-1:0] Q7,
    output signed [DATA_WIDTH-1:0] Q8
);

    wire signed [DATA_WIDTH-1:0] I1_i, I2_i, I3_i, I4_i, I5_i, I6_i, I7_i, I8_i;
    wire signed [DATA_WIDTH-1:0] Q1_i, Q2_i, Q3_i, Q4_i, Q5_i, Q6_i, Q7_i, Q8_i;

    assign { I8_i, I7_i, I6_i, I5_i, I4_i, I3_i, I2_i, I1_i } = I;
    assign { Q8_i, Q7_i, Q6_i, Q5_i, Q4_i, Q3_i, Q2_i, Q1_i } = Q;

    // Only the high 12 bits from the ADC are useful, so we shift the value by 4.
    // Kai 07/05/2024: RFSoC 4x2 has 14bit ADC. But the computation is based on 12-bit data.
   // localparam SHIFT = 2;

    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_1 (
        .ang(2'b00),
        .I_i(I1_i >>> SHIFT),
        .Q_i(Q1_i >>> SHIFT),
        .I_o(I1),
        .Q_o(Q1)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_2 (
        .ang(2'b01),
        .I_i(I2_i >>> SHIFT),
        .Q_i(Q2_i >>> SHIFT),
        .I_o(I2),
        .Q_o(Q2)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_3 (
        .ang(2'b10),
        .I_i(I3_i >>> SHIFT),
        .Q_i(Q3_i >>> SHIFT),
        .I_o(I3),
        .Q_o(Q3)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_4 (
        .ang(2'b11),
        .I_i(I4_i >>> SHIFT),
        .Q_i(Q4_i >>> SHIFT),
        .I_o(I4),
        .Q_o(Q4)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_5 (
        .ang(2'b00),
        .I_i(I5_i >>> SHIFT),
        .Q_i(Q5_i >>> SHIFT),
        .I_o(I5),
        .Q_o(Q5)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_6 (
        .ang(2'b01),
        .I_i(I6_i >>> SHIFT),
        .Q_i(Q6_i >>> SHIFT),
        .I_o(I6),
        .Q_o(Q6)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_7 (
        .ang(2'b10),
        .I_i(I7_i >>> SHIFT),
        .Q_i(Q7_i >>> SHIFT),
        .I_o(I7),
        .Q_o(Q7)
    );
    Derotate #(.DATA_WIDTH(DATA_WIDTH)) Derot_8 (
        .ang(2'b11),
        .I_i(I8_i >>> SHIFT),
        .Q_i(Q8_i >>> SHIFT),
        .I_o(I8),
        .Q_o(Q8)
    );

endmodule
