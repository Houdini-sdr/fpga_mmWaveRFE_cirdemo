/**
 * Module     : Golay_Corr
 * Description: Golay-sequence correlation of length 128.
 * Author     : Wuqiong Zhao (me@wqzhao.org)
 *
 * Created    : 2023-05-31
 *
 */

module Golay_Corr #(
    parameter DATA_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   en,
    input  signed [DATA_WIDTH-1:0] I1,
    input  signed [DATA_WIDTH-1:0] I2,
    input  signed [DATA_WIDTH-1:0] I3,
    input  signed [DATA_WIDTH-1:0] I4,
    input  signed [DATA_WIDTH-1:0] I5,
    input  signed [DATA_WIDTH-1:0] I6,
    input  signed [DATA_WIDTH-1:0] I7,
    input  signed [DATA_WIDTH-1:0] I8,
    output signed [DATA_WIDTH-1:0] Ra1,
    output signed [DATA_WIDTH-1:0] Ra2,
    output signed [DATA_WIDTH-1:0] Ra3,
    output signed [DATA_WIDTH-1:0] Ra4,
    output signed [DATA_WIDTH-1:0] Ra5,
    output signed [DATA_WIDTH-1:0] Ra6,
    output signed [DATA_WIDTH-1:0] Ra7,
    output signed [DATA_WIDTH-1:0] Ra8,
    output signed [DATA_WIDTH-1:0] Rb1,
    output signed [DATA_WIDTH-1:0] Rb2,
    output signed [DATA_WIDTH-1:0] Rb3,
    output signed [DATA_WIDTH-1:0] Rb4,
    output signed [DATA_WIDTH-1:0] Rb5,
    output signed [DATA_WIDTH-1:0] Rb6,
    output signed [DATA_WIDTH-1:0] Rb7,
    output signed [DATA_WIDTH-1:0] Rb8
);

    // ===== Constants =====
    localparam M = 7; // 2^7 = 128
    localparam SSR = 8; // supersampling rate

    wire signed [DATA_WIDTH-1:0] delay_I1[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I2[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I3[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I4[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I5[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I6[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I7[0:M];
    wire signed [DATA_WIDTH-1:0] delay_I8[0:M];
    wire signed [DATA_WIDTH-1:0] sum_I1  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I2  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I3  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I4  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I5  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I6  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I7  [0:M];
    wire signed [DATA_WIDTH-1:0] sum_I8  [0:M];

    // Input Assign
    assign delay_I1[0] = I1;
    assign delay_I2[0] = I2;
    assign delay_I3[0] = I3;
    assign delay_I4[0] = I4;
    assign delay_I5[0] = I5;
    assign delay_I6[0] = I6;
    assign delay_I7[0] = I7;
    assign delay_I8[0] = I8;
    assign sum_I1[0] = I1;
    assign sum_I2[0] = I2;
    assign sum_I3[0] = I3;
    assign sum_I4[0] = I4;
    assign sum_I5[0] = I5;
    assign sum_I6[0] = I6;
    assign sum_I7[0] = I7;
    assign sum_I8[0] = I8;

    // Pipeline Registers (M-1 cc)
    wire signed [DATA_WIDTH-1:0] reg_delay_I1[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I2[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I3[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I4[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I5[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I6[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I7[1:M];
    wire signed [DATA_WIDTH-1:0] reg_delay_I8[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I1[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I2[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I3[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I4[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I5[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I6[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I7[1:M];
    wire signed [DATA_WIDTH-1:0] reg_sum_I8[1:M];

    // According to IEEE 802.11ad standard, the CES has the following Golay configurations.
    // DELAYS : 1, 8, 2, 4, 16, 32, 64
    // WEIGHTS: -1, -1, -1, -1, +1, -1, -1

    // ===== STAGE 1 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1), .HALF(0)) gc1_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I1[0]),
        .Ib(delay_I8[0]),
        .Oa(sum_I1[1]),
        .Ob(delay_I1[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I2[0]),
        .Ib(delay_I1[0]),
        .Oa(sum_I2[1]),
        .Ob(delay_I2[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I3[0]),
        .Ib(delay_I2[0]),
        .Oa(sum_I3[1]),
        .Ob(delay_I3[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I4[0]),
        .Ib(delay_I3[0]),
        .Oa(sum_I4[1]),
        .Ob(delay_I4[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I5[0]),
        .Ib(delay_I4[0]),
        .Oa(sum_I5[1]),
        .Ob(delay_I5[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I6[0]),
        .Ib(delay_I5[0]),
        .Oa(sum_I6[1]),
        .Ob(delay_I6[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I7[0]),
        .Ib(delay_I6[0]),
        .Oa(sum_I7[1]),
        .Ob(delay_I7[1])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0), .HALF(0)) gc1_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(sum_I8[0]),
        .Ib(delay_I7[0]),
        .Oa(sum_I8[1]),
        .Ob(delay_I8[1])
    );

    // ===== STAGE 2 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[1]),
        .Ib(reg_delay_I1[1]),
        .Oa(sum_I1[2]),
        .Ob(delay_I1[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[1]),
        .Ib(reg_delay_I2[1]),
        .Oa(sum_I2[2]),
        .Ob(delay_I2[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[1]),
        .Ib(reg_delay_I3[1]),
        .Oa(sum_I3[2]),
        .Ob(delay_I3[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[1]),
        .Ib(reg_delay_I4[1]),
        .Oa(sum_I4[2]),
        .Ob(delay_I4[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[1]),
        .Ib(reg_delay_I5[1]),
        .Oa(sum_I5[2]),
        .Ob(delay_I5[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[1]),
        .Ib(reg_delay_I6[1]),
        .Oa(sum_I6[2]),
        .Ob(delay_I6[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[1]),
        .Ib(reg_delay_I7[1]),
        .Oa(sum_I7[2]),
        .Ob(delay_I7[2])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc2_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[1]),
        .Ib(reg_delay_I8[1]),
        .Oa(sum_I8[2]),
        .Ob(delay_I8[2])
    );

    // ===== STAGE 3 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc3_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[2]),
        .Ib(reg_delay_I7[2]),
        .Oa(sum_I1[3]),
        .Ob(delay_I1[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc3_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[2]),
        .Ib(reg_delay_I8[2]),
        .Oa(sum_I2[3]),
        .Ob(delay_I2[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[2]),
        .Ib(reg_delay_I1[2]),
        .Oa(sum_I3[3]),
        .Ob(delay_I3[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[2]),
        .Ib(reg_delay_I2[2]),
        .Oa(sum_I4[3]),
        .Ob(delay_I4[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[2]),
        .Ib(reg_delay_I3[2]),
        .Oa(sum_I5[3]),
        .Ob(delay_I5[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[2]),
        .Ib(reg_delay_I4[2]),
        .Oa(sum_I6[3]),
        .Ob(delay_I6[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[2]),
        .Ib(reg_delay_I5[2]),
        .Oa(sum_I7[3]),
        .Ob(delay_I7[3])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc3_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[2]),
        .Ib(reg_delay_I6[2]),
        .Oa(sum_I8[3]),
        .Ob(delay_I8[3])
    );

    // ===== STAGE 4 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc4_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[3]),
        .Ib(reg_delay_I5[3]),
        .Oa(sum_I1[4]),
        .Ob(delay_I1[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc4_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[3]),
        .Ib(reg_delay_I6[3]),
        .Oa(sum_I2[4]),
        .Ob(delay_I2[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc4_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[3]),
        .Ib(reg_delay_I7[3]),
        .Oa(sum_I3[4]),
        .Ob(delay_I3[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(1)) gc4_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[3]),
        .Ib(reg_delay_I8[3]),
        .Oa(sum_I4[4]),
        .Ob(delay_I4[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc4_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[3]),
        .Ib(reg_delay_I1[3]),
        .Oa(sum_I5[4]),
        .Ob(delay_I5[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc4_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[3]),
        .Ib(reg_delay_I2[3]),
        .Oa(sum_I6[4]),
        .Ob(delay_I6[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc4_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[3]),
        .Ib(reg_delay_I3[3]),
        .Oa(sum_I7[4]),
        .Ob(delay_I7[4])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(0)) gc4_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[3]),
        .Ib(reg_delay_I4[3]),
        .Oa(sum_I8[4]),
        .Ob(delay_I8[4])
    );

    // ===== STAGE 5 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[4]),
        .Ib(reg_delay_I1[4]),
        .Oa(sum_I1[5]),
        .Ob(delay_I1[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[4]),
        .Ib(reg_delay_I2[4]),
        .Oa(sum_I2[5]),
        .Ob(delay_I2[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[4]),
        .Ib(reg_delay_I3[4]),
        .Oa(sum_I3[5]),
        .Ob(delay_I3[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[4]),
        .Ib(reg_delay_I4[4]),
        .Oa(sum_I4[5]),
        .Ob(delay_I4[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[4]),
        .Ib(reg_delay_I5[4]),
        .Oa(sum_I5[5]),
        .Ob(delay_I5[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[4]),
        .Ib(reg_delay_I6[4]),
        .Oa(sum_I6[5]),
        .Ob(delay_I6[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[4]),
        .Ib(reg_delay_I7[4]),
        .Oa(sum_I7[5]),
        .Ob(delay_I7[5])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(1), .DELAY(2)) gc5_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[4]),
        .Ib(reg_delay_I8[4]),
        .Oa(sum_I8[5]),
        .Ob(delay_I8[5])
    );

    // ===== STAGE 6 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[5]),
        .Ib(reg_delay_I1[5]),
        .Oa(sum_I1[6]),
        .Ob(delay_I1[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[5]),
        .Ib(reg_delay_I2[5]),
        .Oa(sum_I2[6]),
        .Ob(delay_I2[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[5]),
        .Ib(reg_delay_I3[5]),
        .Oa(sum_I3[6]),
        .Ob(delay_I3[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[5]),
        .Ib(reg_delay_I4[5]),
        .Oa(sum_I4[6]),
        .Ob(delay_I4[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[5]),
        .Ib(reg_delay_I5[5]),
        .Oa(sum_I5[6]),
        .Ob(delay_I5[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[5]),
        .Ib(reg_delay_I6[5]),
        .Oa(sum_I6[6]),
        .Ob(delay_I6[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[5]),
        .Ib(reg_delay_I7[5]),
        .Oa(sum_I7[6]),
        .Ob(delay_I7[6])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(4)) gc6_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[5]),
        .Ib(reg_delay_I8[5]),
        .Oa(sum_I8[6]),
        .Ob(delay_I8[6])
    );

    // ===== STAGE 7 ====== //
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_1 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I1[6]),
        .Ib(reg_delay_I1[6]),
        .Oa(sum_I1[7]),
        .Ob(delay_I1[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_2 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I2[6]),
        .Ib(reg_delay_I2[6]),
        .Oa(sum_I2[7]),
        .Ob(delay_I2[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_3 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I3[6]),
        .Ib(reg_delay_I3[6]),
        .Oa(sum_I3[7]),
        .Ob(delay_I3[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_4 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I4[6]),
        .Ib(reg_delay_I4[6]),
        .Oa(sum_I4[7]),
        .Ob(delay_I4[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_5 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I5[6]),
        .Ib(reg_delay_I5[6]),
        .Oa(sum_I5[7]),
        .Ob(delay_I5[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_6 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I6[6]),
        .Ib(reg_delay_I6[6]),
        .Oa(sum_I6[7]),
        .Ob(delay_I6[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_7 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I7[6]),
        .Ib(reg_delay_I7[6]),
        .Oa(sum_I7[7]),
        .Ob(delay_I7[7])
    );
    Golay_Corr_Sub #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT(0), .DELAY(8)) gc7_8 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Ia(reg_sum_I8[6]),
        .Ib(reg_delay_I8[6]),
        .Oa(sum_I8[7]),
        .Ob(delay_I8[7])
    );

    generate
        genvar i;
        for (i = 1; i <= M; i = i + 1) begin: PIPELINE
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_1 (
                .clk(clk),
                .rst(rst),
                .in(delay_I1[i]),
                .out(reg_delay_I1[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_2 (
                .clk(clk),
                .rst(rst),
                .in(delay_I2[i]),
                .out(reg_delay_I2[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_3 (
                .clk(clk),
                .rst(rst),
                .in(delay_I3[i]),
                .out(reg_delay_I3[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_4 (
                .clk(clk),
                .rst(rst),
                .in(delay_I4[i]),
                .out(reg_delay_I4[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_5 (
                .clk(clk),
                .rst(rst),
                .in(delay_I5[i]),
                .out(reg_delay_I5[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_6 (
                .clk(clk),
                .rst(rst),
                .in(delay_I6[i]),
                .out(reg_delay_I6[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_7 (
                .clk(clk),
                .rst(rst),
                .in(delay_I7[i]),
                .out(reg_delay_I7[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_delay_8 (
                .clk(clk),
                .rst(rst),
                .in(delay_I8[i]),
                .out(reg_delay_I8[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_1 (
                .clk(clk),
                .rst(rst),
                .in(sum_I1[i]),
                .out(reg_sum_I1[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_2 (
                .clk(clk),
                .rst(rst),
                .in(sum_I2[i]),
                .out(reg_sum_I2[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_3 (
                .clk(clk),
                .rst(rst),
                .in(sum_I3[i]),
                .out(reg_sum_I3[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_4 (
                .clk(clk),
                .rst(rst),
                .in(sum_I4[i]),
                .out(reg_sum_I4[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_5 (
                .clk(clk),
                .rst(rst),
                .in(sum_I5[i]),
                .out(reg_sum_I5[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_6 (
                .clk(clk),
                .rst(rst),
                .in(sum_I6[i]),
                .out(reg_sum_I6[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_7 (
                .clk(clk),
                .rst(rst),
                .in(sum_I7[i]),
                .out(reg_sum_I7[i])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) Pipe_D_sum_8 (
                .clk(clk),
                .rst(rst),
                .in(sum_I8[i]),
                .out(reg_sum_I8[i])
            );
        end
    endgenerate

    // Output Assign
    assign Ra1 = reg_sum_I1[M];
    assign Ra2 = reg_sum_I2[M];
    assign Ra3 = reg_sum_I3[M];
    assign Ra4 = reg_sum_I4[M];
    assign Ra5 = reg_sum_I5[M];
    assign Ra6 = reg_sum_I6[M];
    assign Ra7 = reg_sum_I7[M];
    assign Ra8 = reg_sum_I8[M];
    assign Rb1 = reg_delay_I1[M];
    assign Rb2 = reg_delay_I2[M];
    assign Rb3 = reg_delay_I3[M];
    assign Rb4 = reg_delay_I4[M];
    assign Rb5 = reg_delay_I5[M];
    assign Rb6 = reg_delay_I6[M];
    assign Rb7 = reg_delay_I7[M];
    assign Rb8 = reg_delay_I8[M];

endmodule
