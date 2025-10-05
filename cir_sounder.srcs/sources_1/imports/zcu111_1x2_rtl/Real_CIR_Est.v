module Real_CIR_Est #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst,
    input en,
    input  [3:0] cnt_init,
    input  signed [DATA_WIDTH-1:0] I1,
    input  signed [DATA_WIDTH-1:0] I2,
    input  signed [DATA_WIDTH-1:0] I3,
    input  signed [DATA_WIDTH-1:0] I4,
    input  signed [DATA_WIDTH-1:0] I5,
    input  signed [DATA_WIDTH-1:0] I6,
    input  signed [DATA_WIDTH-1:0] I7,
    input  signed [DATA_WIDTH-1:0] I8,
    output reg signed [DATA_WIDTH-1:0] O1,
    output reg signed [DATA_WIDTH-1:0] O2,
    output reg signed [DATA_WIDTH-1:0] O3,
    output reg signed [DATA_WIDTH-1:0] O4,
    output reg signed [DATA_WIDTH-1:0] O5,
    output reg signed [DATA_WIDTH-1:0] O6,
    output reg signed [DATA_WIDTH-1:0] O7,
    output reg signed [DATA_WIDTH-1:0] O8,
    output start,
    output last     // added by Kai 2024-5
);

    localparam SSR = 8;
    localparam SHIFT = 128 / SSR; // Ga and Gb is shifted by 128/SSR.

    localparam M     = 7;
    localparam CORR_PIPE = M-1;
    localparam REP   = 4;   // 4 repeats of {Ga, Gb} sequences omitting the last Gv128.

    reg [11:0] cnt; // clock count
    reg signed [DATA_WIDTH-1:0] CIR1[0:2*SHIFT-1], CIR2[0:2*SHIFT-1], CIR3[0:2*SHIFT-1], CIR4[0:2*SHIFT-1], CIR5[0:2*SHIFT-1], CIR6[0:2*SHIFT-1], CIR7[0:2*SHIFT-1], CIR8[0:2*SHIFT-1];

    wire signed [DATA_WIDTH-1:0] Ra1, Ra2, Ra3, Ra4, Ra5, Ra6, Ra7, Ra8, Rb1, Rb2, Rb3, Rb4, Rb5, Rb6, Rb7, Rb8;

    reg FIFO_en;
    reg CIR_last;

    Golay_Corr #(.DATA_WIDTH(DATA_WIDTH)) GolayCorr (
        .clk(clk),
        .rst(rst),
        .en(en),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I5(I5),
        .I6(I6),
        .I7(I7),
        .I8(I8),
        .Ra1(Ra1),
        .Ra2(Ra2),
        .Ra3(Ra3),
        .Ra4(Ra4),
        .Ra5(Ra5),
        .Ra6(Ra6),
        .Ra7(Ra7),
        .Ra8(Ra8),
        .Rb1(Rb1),
        .Rb2(Rb2),
        .Rb3(Rb3),
        .Rb4(Rb4),
        .Rb5(Rb5),
        .Rb6(Rb6),
        .Rb7(Rb7),
        .Rb8(Rb8)
    );

    wire [DATA_WIDTH-1:0] Ra1_shift, Ra2_shift, Ra3_shift, Ra4_shift, Ra5_shift, Ra6_shift, Ra7_shift, Ra8_shift;
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_1 (
        .clk(clk),
        .rst(rst),
        .in(Ra1),
        .out(Ra1_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_2 (
        .clk(clk),
        .rst(rst),
        .in(Ra2),
        .out(Ra2_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_3 (
        .clk(clk),
        .rst(rst),
        .in(Ra3),
        .out(Ra3_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_4 (
        .clk(clk),
        .rst(rst),
        .in(Ra4),
        .out(Ra4_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_5 (
        .clk(clk),
        .rst(rst),
        .in(Ra5),
        .out(Ra5_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_6 (
        .clk(clk),
        .rst(rst),
        .in(Ra6),
        .out(Ra6_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_7 (
        .clk(clk),
        .rst(rst),
        .in(Ra7),
        .out(Ra7_shift)
    );
    Delay_n #(.DATA_WIDTH(DATA_WIDTH), .DELAY(SHIFT)) D_shift_8 (
        .clk(clk),
        .rst(rst),
        .in(Ra8),
        .out(Ra8_shift)
    );

    reg [1:0] signs;
    reg signed [DATA_WIDTH-1:0] CIR_sampled1, CIR_sampled2, CIR_sampled3, CIR_sampled4, CIR_sampled5, CIR_sampled6, CIR_sampled7, CIR_sampled8;

    integer i;

    wire [4:0] cnt_minus, cnt_minus_; // 5 bits, because 32 CIR values, with 8 SSR.
    // assign cnt_minus_ = cnt[4:0] - (CORR_PIPE+1);
    assign cnt_minus_ = cnt[4:0] - CORR_PIPE;

    // add this pipeline because 
    Delay_1 #(.DATA_WIDTH(5)) D_cnt_minus (
        .clk(clk),
        .rst(rst),
        .in(cnt_minus_),
        .out(cnt_minus)
    );

    always @(posedge clk) begin
        if (rst) begin
            cnt <= cnt_init;
            FIFO_en <= 0;
            CIR_last <= 0;      // Kai 05/15/2024
            signs <= 2'b01;
            CIR_sampled1 <= 0;
            CIR_sampled2 <= 0;
            CIR_sampled3 <= 0;
            CIR_sampled4 <= 0;
            CIR_sampled5 <= 0;
            CIR_sampled6 <= 0;
            CIR_sampled7 <= 0;
            CIR_sampled8 <= 0;
            for (i = 0; i != 2*SHIFT; i = i+1) begin: INIT_CIR
                CIR1[i] <= 0;
                CIR2[i] <= 0;
                CIR3[i] <= 0;
                CIR4[i] <= 0;
                CIR5[i] <= 0;
                CIR6[i] <= 0;
                CIR7[i] <= 0;
                CIR8[i] <= 0;
            end
        end
        else begin
            if (cnt >= 2 * SHIFT + CORR_PIPE) begin
                case (cnt)
                    4 * SHIFT + CORR_PIPE: signs[0] = 0;
                    6 * SHIFT + CORR_PIPE: signs[1] = 1;
                    8 * SHIFT + CORR_PIPE: signs[1] = 0;
                    default:; // otherwise make no change the signs
                endcase
                case (signs)
                    2'b00  : begin CIR_sampled1 <= -Ra1_shift - Rb1; CIR_sampled2 <= -Ra2_shift - Rb2; CIR_sampled3 <= -Ra3_shift - Rb3; CIR_sampled4 <= -Ra4_shift - Rb4; CIR_sampled5 <= -Ra5_shift - Rb5; CIR_sampled6 <= -Ra6_shift - Rb6; CIR_sampled7 <= -Ra7_shift - Rb7; CIR_sampled8 <= -Ra8_shift - Rb8; end
                    2'b01  : begin CIR_sampled1 <= -Ra1_shift + Rb1; CIR_sampled2 <= -Ra2_shift + Rb2; CIR_sampled3 <= -Ra3_shift + Rb3; CIR_sampled4 <= -Ra4_shift + Rb4; CIR_sampled5 <= -Ra5_shift + Rb5; CIR_sampled6 <= -Ra6_shift + Rb6; CIR_sampled7 <= -Ra7_shift + Rb7; CIR_sampled8 <= -Ra8_shift + Rb8; end
                    2'b10  : begin CIR_sampled1 <= +Ra1_shift - Rb1; CIR_sampled2 <= +Ra2_shift - Rb2; CIR_sampled3 <= +Ra3_shift - Rb3; CIR_sampled4 <= +Ra4_shift - Rb4; CIR_sampled5 <= +Ra5_shift - Rb5; CIR_sampled6 <= +Ra6_shift - Rb6; CIR_sampled7 <= +Ra7_shift - Rb7; CIR_sampled8 <= +Ra8_shift - Rb8; end
                    2'b11  : begin CIR_sampled1 <= +Ra1_shift + Rb1; CIR_sampled2 <= +Ra2_shift + Rb2; CIR_sampled3 <= +Ra3_shift + Rb3; CIR_sampled4 <= +Ra4_shift + Rb4; CIR_sampled5 <= +Ra5_shift + Rb5; CIR_sampled6 <= +Ra6_shift + Rb6; CIR_sampled7 <= +Ra7_shift + Rb7; CIR_sampled8 <= +Ra8_shift + Rb8; end
                    default: begin CIR_sampled1 <= -Ra1_shift - Rb1; CIR_sampled2 <= -Ra2_shift - Rb2; CIR_sampled3 <= -Ra3_shift - Rb3; CIR_sampled4 <= -Ra4_shift - Rb4; CIR_sampled5 <= -Ra5_shift - Rb5; CIR_sampled6 <= -Ra6_shift - Rb6; CIR_sampled7 <= -Ra7_shift - Rb7; CIR_sampled8 <= -Ra8_shift - Rb8; end
                endcase
            end
            else begin
                CIR_sampled1 <= 0;
                CIR_sampled2 <= 0;
                CIR_sampled3 <= 0;
                CIR_sampled4 <= 0;
                CIR_sampled5 <= 0;
                CIR_sampled6 <= 0;
                CIR_sampled7 <= 0;
                CIR_sampled8 <= 0;
            end
            
            CIR1[cnt_minus] <= CIR1[cnt_minus] + CIR_sampled1;
            CIR2[cnt_minus] <= CIR2[cnt_minus] + CIR_sampled2;
            CIR3[cnt_minus] <= CIR3[cnt_minus] + CIR_sampled3;
            CIR4[cnt_minus] <= CIR4[cnt_minus] + CIR_sampled4;
            CIR5[cnt_minus] <= CIR5[cnt_minus] + CIR_sampled5;
            CIR6[cnt_minus] <= CIR6[cnt_minus] + CIR_sampled6;
            CIR7[cnt_minus] <= CIR7[cnt_minus] + CIR_sampled7;
            CIR8[cnt_minus] <= CIR8[cnt_minus] + CIR_sampled8;
            
            if (cnt > 8 * SHIFT + CORR_PIPE) begin
                if (cnt <= 10 * SHIFT + CORR_PIPE) begin
                    FIFO_en <= 1;
                    O1 <= CIR1[cnt_minus];
                    O2 <= CIR2[cnt_minus];
                    O3 <= CIR3[cnt_minus];
                    O4 <= CIR4[cnt_minus];
                    O5 <= CIR5[cnt_minus];
                    O6 <= CIR6[cnt_minus];
                    O7 <= CIR7[cnt_minus];
                    O8 <= CIR8[cnt_minus];
                end
                else begin
                    FIFO_en <= 0;
                end
                // Kai: 2024-05-02
                if (cnt == 10 * SHIFT + CORR_PIPE) begin
                    CIR_last <= 1;
                end else begin 
                    CIR_last <= 0;
                end
            end

            if (en) cnt <= cnt + 1;
        end
    end

    assign start = FIFO_en;
    assign last = CIR_last;
endmodule
