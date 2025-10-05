module BD_Detect #(
    parameter DATA_WIDTH = 16
) (
    input en,
    input clk,
    input rst,
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
    input signed [15:0] BAC_TH,
    input [3:0] NAC_SHIFT,
    input [3:0] NAC_CC,
    input [3:0] BAC_CC,
    input [7:0] PD_BD_Delay,
    output reg PD_FLAG,
    output reg BD_FLAG,
    output reg signed [15:0] NAC_L_Debug, 
    output reg signed [15:0] NAC_R_Debug,
    output reg signed [15:0] BAC_L_Debug
);

    localparam SSR = 8;
    localparam M = 7;
    localparam N = 1 << M; // 128
    localparam SHIFT = N / SSR; // 32

    wire signed [DATA_WIDTH-1:0] ID [0:2*N-1], QD [0:2*N-1];
    wire signed [9:0] I_mul0 [0:127], I_mul64 [0:31], I_mul128 [0:127];
    wire signed [9:0] Q_mul0 [0:127], Q_mul64 [0:31], Q_mul128 [0:127];

    assign ID[0] = I1;
    assign ID[1] = I2;
    assign ID[2] = I3;
    assign ID[3] = I4;
    assign ID[4] = I5;
    assign ID[5] = I6;
    assign ID[6] = I7;
    assign ID[7] = I8;
    assign QD[0] = Q1;
    assign QD[1] = Q2;
    assign QD[2] = Q3;
    assign QD[3] = Q4;
    assign QD[4] = Q5;
    assign QD[5] = Q6;
    assign QD[6] = Q7;
    assign QD[7] = Q8;

    // ===== Delayed Signals from 0 to 128 ===== //
    genvar i;
    generate
        for (i = 0; i != 2 * N - SSR; i = i + 1) begin: DELAYED
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) delay_I (
                .clk(clk),
                .rst(rst),
                .in(ID[i]),
                .out(ID[i + SSR])
            );
            Delay_1 #(.DATA_WIDTH(DATA_WIDTH)) delay_Q (
                .clk(clk),
                .rst(rst),
                .in(QD[i]),
                .out(QD[i + SSR])
            );
        end
    endgenerate

    // ==== Multipliers ===== //
    genvar i128;
    generate
        for (i128 = 128; i128 != 256; i128 = i128 + 1) begin: MUL_128
            Complex_Mul #(.I_WIDTH(5), .O_WIDTH(10), .CONJ(1), .DELAY(4)) mul_128 (
                .en(en),
                .clk(clk),
                .rst(rst),
                .I1(ID[i128][11:7]),
                .Q1(QD[i128][11:7]),
                .I2(ID[i128-128][11:7]),
                .Q2(QD[i128-128][11:7]),
                .Io(I_mul128[i128-128]),
                .Qo(Q_mul128[i128-128])
            );
            // Complex_Mul #(.I_WIDTH(5), .O_WIDTH(10), .CONJ(1), .DELAY(4)) mul_0 (
            //     .en(en),
            //     .clk(clk),
            //     .rst(rst),
            //     .I1(ID[i128][11:7]),
            //     .Q1(QD[i128][11:7]),
            //     .I2(ID[i128][11:7]),
            //     .Q2(QD[i128][11:7]),
            //     .Io(I_mul0[i128-128]),
            //     .Qo(Q_mul0[i128-128])
            // );
            Complex_Abs2 #(.I_WIDTH(5), .O_WIDTH(10), .DELAY(4)) mul_0 (
                .clk(clk),
                .rst(rst),
                .I(ID[i128][11:7]),
                .Q(QD[i128][11:7]),
                .O(I_mul0[i128-128])
            );
        end
    endgenerate
    genvar i32;
    generate
        for (i32 = 128; i32 != 128 + 32; i32 = i32 + 1) begin: MUL_32
            Complex_Mul #(.I_WIDTH(5), .O_WIDTH(10), .CONJ(1), .DELAY(4)) mul_64 (
                .en(en),
                .clk(clk),
                .rst(rst),
                .I1(ID[i32][11:7]),
                .Q1(QD[i32][11:7]),
                .I2(ID[i32-64][11:7]),
                .Q2(QD[i32-64][11:7]),
                .Io(I_mul64[i32-128]),
                .Qo(Q_mul64[i32-128])
            );
        end
    endgenerate

    // ===== Adder Tree ===== //
    wire signed [10:0] I_mul0_adt_l1 [0:64-1];
    wire signed [11:0] I_mul0_adt_l2 [0:32-1];
    wire signed [12:0] I_mul0_adt_l3 [0:16-1];
    wire signed [13:0] I_mul0_adt_l4 [0: 8-1];
    wire signed [14:0] I_mul0_adt_l5 [0: 4-1];
    wire signed [15:0] I_mul0_adt_l6 [0: 2-1];
    wire signed [16:0] I_mul0_sum128         ;
    wire signed [10:0] I_mul128_adt_l1 [0:64-1], Q_mul128_adt_l1 [0:64-1];
    wire signed [11:0] I_mul128_adt_l2 [0:32-1], Q_mul128_adt_l2 [0:32-1];
    wire signed [12:0] I_mul128_adt_l3 [0:16-1], Q_mul128_adt_l3 [0:16-1];
    wire signed [13:0] I_mul128_adt_l4 [0: 8-1], Q_mul128_adt_l4 [0: 8-1];
    wire signed [14:0] I_mul128_adt_l5 [0: 4-1], Q_mul128_adt_l5 [0: 4-1];
    wire signed [15:0] I_mul128_adt_l6 [0: 2-1], Q_mul128_adt_l6 [0: 2-1];
    wire signed [16:0] I_mul128_sum128         , Q_mul128_sum128         ;
    wire signed [14:0] I_mul128_sum32          , Q_mul128_sum32          ;
    wire signed [10:0] I_mul64_adt_l3 [0:16-1], Q_mul64_adt_l3 [0:16-1];
    wire signed [11:0] I_mul64_adt_l4 [0: 8-1], Q_mul64_adt_l4 [0: 8-1];
    wire signed [12:0] I_mul64_adt_l5 [0: 4-1], Q_mul64_adt_l5 [0: 4-1];
    wire signed [13:0] I_mul64_adt_l6 [0: 2-1], Q_mul64_adt_l6 [0: 2-1];
    wire signed [14:0] I_mul64_sum32          , Q_mul64_sum32          ;
    assign I_mul128_sum32 = I_mul128_adt_l5[0];
    assign Q_mul128_sum32 = Q_mul128_adt_l5[0];
    genvar i_adt;
    generate
        for (i_adt = 0; i_adt != 64; i_adt = i_adt + 1) begin: ADT_L1
            Real_Add #(.DATA_WIDTH(10), .DELAY(1)) mul_0_s_l1 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0[2*i_adt]),
                .I2(I_mul0[2*i_adt+1]),
                .Io(I_mul0_adt_l1[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(10), .DELAY(1)) mul_128_s_l1 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128[2*i_adt]),
                .Q1(Q_mul128[2*i_adt]),
                .I2(I_mul128[2*i_adt+1]),
                .Q2(Q_mul128[2*i_adt+1]),
                .Io(I_mul128_adt_l1[i_adt]),
                .Qo(Q_mul128_adt_l1[i_adt])
            );
        end
        for (i_adt = 0; i_adt != 32; i_adt = i_adt + 1) begin: ADT_L2
            Real_Add #(.DATA_WIDTH(11), .DELAY(1)) mul_0_s_l2 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0_adt_l1[2*i_adt]),
                .I2(I_mul0_adt_l1[2*i_adt+1]),
                .Io(I_mul0_adt_l2[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(11), .DELAY(1)) mul_128_s_l2 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128_adt_l1[2*i_adt]),
                .Q1(Q_mul128_adt_l1[2*i_adt]),
                .I2(I_mul128_adt_l1[2*i_adt+1]),
                .Q2(Q_mul128_adt_l1[2*i_adt+1]),
                .Io(I_mul128_adt_l2[i_adt]),
                .Qo(Q_mul128_adt_l2[i_adt])
            );
        end
        for (i_adt = 0; i_adt != 16; i_adt = i_adt + 1) begin: ADT_L3
            Real_Add #(.DATA_WIDTH(12), .DELAY(1)) mul_0_s_l3 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0_adt_l2[2*i_adt]),
                .I2(I_mul0_adt_l2[2*i_adt+1]),
                .Io(I_mul0_adt_l3[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(12), .DELAY(1)) mul_128_s_l3 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128_adt_l2[2*i_adt]),
                .Q1(Q_mul128_adt_l2[2*i_adt]),
                .I2(I_mul128_adt_l2[2*i_adt+1]),
                .Q2(Q_mul128_adt_l2[2*i_adt+1]),
                .Io(I_mul128_adt_l3[i_adt]),
                .Qo(Q_mul128_adt_l3[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(10), .DELAY(1)) mul_64_s_l3 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul64[2*i_adt]),
                .Q1(Q_mul64[2*i_adt]),
                .I2(I_mul64[2*i_adt+1]),
                .Q2(Q_mul64[2*i_adt+1]),
                .Io(I_mul64_adt_l3[i_adt]),
                .Qo(Q_mul64_adt_l3[i_adt])
            );
        end
        for (i_adt = 0; i_adt != 8; i_adt = i_adt + 1) begin: ADT_L4
            Real_Add #(.DATA_WIDTH(13), .DELAY(1)) mul_0_s_l4 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0_adt_l3[2*i_adt]),
                .I2(I_mul0_adt_l3[2*i_adt+1]),
                .Io(I_mul0_adt_l4[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(13), .DELAY(1)) mul_128_s_l4 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128_adt_l3[2*i_adt]),
                .Q1(Q_mul128_adt_l3[2*i_adt]),
                .I2(I_mul128_adt_l3[2*i_adt+1]),
                .Q2(Q_mul128_adt_l3[2*i_adt+1]),
                .Io(I_mul128_adt_l4[i_adt]),
                .Qo(Q_mul128_adt_l4[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(11), .DELAY(1)) mul_64_s_l4 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul64_adt_l3[2*i_adt]),
                .Q1(Q_mul64_adt_l3[2*i_adt]),
                .I2(I_mul64_adt_l3[2*i_adt+1]),
                .Q2(Q_mul64_adt_l3[2*i_adt+1]),
                .Io(I_mul64_adt_l4[i_adt]),
                .Qo(Q_mul64_adt_l4[i_adt])
            );
        end
        for (i_adt = 0; i_adt != 4; i_adt = i_adt + 1) begin: ADT_L5
            Real_Add #(.DATA_WIDTH(14), .DELAY(1)) mul_0_s_l5 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0_adt_l4[2*i_adt]),
                .I2(I_mul0_adt_l4[2*i_adt+1]),
                .Io(I_mul0_adt_l5[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(14), .DELAY(1)) mul_128_s_l5 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128_adt_l4[2*i_adt]),
                .Q1(Q_mul128_adt_l4[2*i_adt]),
                .I2(I_mul128_adt_l4[2*i_adt+1]),
                .Q2(Q_mul128_adt_l4[2*i_adt+1]),
                .Io(I_mul128_adt_l5[i_adt]),
                .Qo(Q_mul128_adt_l5[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(12), .DELAY(1)) mul_64_s_l5 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul64_adt_l4[2*i_adt]),
                .Q1(Q_mul64_adt_l4[2*i_adt]),
                .I2(I_mul64_adt_l4[2*i_adt+1]),
                .Q2(Q_mul64_adt_l4[2*i_adt+1]),
                .Io(I_mul64_adt_l5[i_adt]),
                .Qo(Q_mul64_adt_l5[i_adt])
            );
        end
        for (i_adt = 0; i_adt != 2; i_adt = i_adt + 1) begin: ADT_L6
            Real_Add #(.DATA_WIDTH(15), .DELAY(1)) mul_0_s_l6 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul0_adt_l5[2*i_adt]),
                .I2(I_mul0_adt_l5[2*i_adt+1]),
                .Io(I_mul0_adt_l6[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(15), .DELAY(1)) mul_128_s_l6 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul128_adt_l5[2*i_adt]),
                .Q1(Q_mul128_adt_l5[2*i_adt]),
                .I2(I_mul128_adt_l5[2*i_adt+1]),
                .Q2(Q_mul128_adt_l5[2*i_adt+1]),
                .Io(I_mul128_adt_l6[i_adt]),
                .Qo(Q_mul128_adt_l6[i_adt])
            );
            Complex_Add #(.DATA_WIDTH(13), .DELAY(1)) mul_64_s_l6 (
                .clk(clk),
                .rst(rst),
                .I1(I_mul64_adt_l5[2*i_adt]),
                .Q1(Q_mul64_adt_l5[2*i_adt]),
                .I2(I_mul64_adt_l5[2*i_adt+1]),
                .Q2(Q_mul64_adt_l5[2*i_adt+1]),
                .Io(I_mul64_adt_l6[i_adt]),
                .Qo(Q_mul64_adt_l6[i_adt])
            );
        end
        // Final Level
        Real_Add #(.DATA_WIDTH(16), .DELAY(1)) mul_0_s_final (
            .clk(clk),
            .rst(rst),
            .I1(I_mul0_adt_l6[0]),
            .I2(I_mul0_adt_l6[1]),
            .Io(I_mul0_sum128)
        );
        Complex_Add #(.DATA_WIDTH(16), .DELAY(1)) mul_128_s_final (
            .clk(clk),
            .rst(rst),
            .I1(I_mul128_adt_l6[0]),
            .Q1(Q_mul128_adt_l6[0]),
            .I2(I_mul128_adt_l6[1]),
            .Q2(Q_mul128_adt_l6[1]),
            .Io(I_mul128_sum128),
            .Qo(Q_mul128_sum128)
        );
        Complex_Add #(.DATA_WIDTH(14), .DELAY(1)) mul_64_s_final (
            .clk(clk),
            .rst(rst),
            .I1(I_mul64_adt_l6[0]),
            .Q1(Q_mul64_adt_l6[0]),
            .I2(I_mul64_adt_l6[1]),
            .Q2(Q_mul64_adt_l6[1]),
            .Io(I_mul64_sum32),
            .Qo(Q_mul64_sum32)
        );
    endgenerate

    // ===== Final Results ===== //
    wire signed [15:0] NAC_L, NAC_R;
    wire signed [15:0] BAC_L;
    Complex_Abs2 #(.I_WIDTH(8), .O_WIDTH(16), .DELAY(2)) NAC_L_abs (
        .clk(clk),
        .rst(rst),
        .I(I_mul128_sum128[16:9]),
        .Q(Q_mul128_sum128[16:9]),
        .O(NAC_L)
    );
    Complex_Abs2 #(.I_WIDTH(8), .O_WIDTH(16), .DELAY(2)) NAC_R_abs (
        .clk(clk),
        .rst(rst),
        .I(I_mul0_sum128[16:9]),
        .Q(8'b0),
        .O(NAC_R)
    );
    assign BAC_L = I_mul64_sum32 + I_mul128_sum32;
    reg NAC_true, BAC_true;

    // ===== FSM ===== //
    reg [3:0] NAC_cnt, BAC_cnt;
    reg [7:0] PD_cnt;   // kai 07/01/2024
    always@(posedge clk, posedge rst) begin
        if (rst) begin
            PD_FLAG <= 0;
            BD_FLAG <= 0;
            NAC_cnt <= 0;
            BAC_cnt <= 0;
            PD_cnt <= 0; // kai 07/01/2024 
            NAC_L_Debug <= 0;
            NAC_R_Debug <= 0;
            BAC_L_Debug <= 0;
        end
        else begin
            if (en) begin
                NAC_L_Debug <= NAC_L;   // Kai 
                NAC_R_Debug <= NAC_R;   // Kai 
                BAC_L_Debug <= BAC_L;   // Kai 
                NAC_true <= (NAC_L > (NAC_R >>> NAC_SHIFT)) & (NAC_R > 16); // with 2 cc latency;  Kai 07/05/2024 Add minimum Pr level
                //BAC_true <= BAC_L < 0;  // Kai: may cause false detection? 
                BAC_true <= BAC_L < (-BAC_TH);  //  Kai
                if (PD_FLAG) begin // already in the package, finding the boundary
                    if (PD_cnt >= PD_BD_Delay) begin // Kai 07/01/2024 : add delay after PD 
                        if (BAC_true && !BD_FLAG) begin
                            BAC_cnt = BAC_cnt + 1;
                            if (BAC_cnt == BAC_CC) BD_FLAG = 1;
                        end
                        else begin
                            BAC_cnt <= 0;
                        end
                    end else begin          // Kai 07/01/2024
                        PD_cnt <= PD_cnt + 1;
                    end
                end
                else begin // looking for the start of the package
                    if (NAC_true) begin
                        NAC_cnt = NAC_cnt + 1;
                        if (NAC_cnt == NAC_CC) PD_FLAG = 1;
                    end
                    else begin
                        NAC_cnt <= 0;
                    end
                end
            end
            else ; // do nothing
        end
    end

endmodule
