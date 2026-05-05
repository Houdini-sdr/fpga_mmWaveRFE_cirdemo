/**
 * Module     : CIR_Extract_1x1_top
 * Description: CIR Extraction With Package/Boundary Detection
 * Author     : Wuqiong Zhao (me@wqzhao.org)
 *
 * Created    : 2023-07-05
 * Updated    : 2023-07-06
 *
 * Modified by Kai, 2024-05-02.
 * Make it Axi-4 Stream compliant for DMA
 */

 module CIR_Extract_1x1_top #(
    parameter DATA_WIDTH = 16 // <--- DO NOT CHANGE
) (
    input  en,
    input  clk,
    input  rst_n,
    // Input FIFOs
    input  [DATA_WIDTH*8-1:0] I_tdata,     // input I data before derotating
    input  [DATA_WIDTH*8-1:0] Q_tdata,     // input Q data before derotating
    input  I_tvalid,
    input  Q_tvalid,
    output I_tready,
    output Q_tready,
    // Output FIFOs
    output [DATA_WIDTH*8-1:0] CIR_I_tdata, // FIFO output for CIR (I)
    output [DATA_WIDTH*8-1:0] CIR_Q_tdata, // FIFO output for CIR (Q)
    output CIR_I_tlast,                     // added by Kai
    output CIR_Q_tlast,                     // added by Kai
    output CIR_I_tvalid,
    output CIR_Q_tvalid,
    input  CIR_I_tready,                   // initially ignored, modified by Kai
    input  CIR_Q_tready,                   // initially ignored, modified by Kai
    //output start,                          // the start of CIR output into FIFO
    // AXI Settings
    input  [31:0] Pr_min,                   // 08-20-2024 added by Kai,
    input  [31:0] BAC_TH,                   // 08-20-2024 added by Kai, 
    input  [3:0] NAC_SHIFT,                // the shift threshold in PD
    input  [15:0] NAC_CC,                   // number of clocks used in PD
    input  [15:0] BAC_CC,                   // number of clocks used in BD
    input  [3:0] SHIFT_CC,                 // shift CIR (i.e. delat GACE_en)
    input  [7:0] PD_BD_Delay,               // kai 07/01/2024 the minimum cc after PD before BD can rise
    input        BYPASS_PD,                // bypass package detection    Kai: default = 1
    input  PD_real,
    input  BD_real,
    output PD_FLAG,                        // package detected
    output BD_FLAG,                        // boundary detected
    output reg GACE_en,                     // start of CIR calculation
    output signed [31:0] NAC_L_Debug,
    output signed [31:0] NAC_R_Debug,
    output signed [29:0] BAC_L_Debug        // 29 --> 12 bit adc
);

    wire rst;
    wire PD_est, BD_est;
    assign i_valid = I_tvalid & Q_tvalid;
    assign rst = ~rst_n;
    
    assign PD_FLAG = BYPASS_PD ? PD_real : PD_est;
    assign BD_FLAG = BYPASS_PD ? BD_real : BD_est;

    reg rst_self;
    reg [3:0] shift_cnt;
    wire start_last_cc;
    
    wire signed [DATA_WIDTH-1:0] I1;
    wire signed [DATA_WIDTH-1:0] I2;
    wire signed [DATA_WIDTH-1:0] I3;
    wire signed [DATA_WIDTH-1:0] I4;
    wire signed [DATA_WIDTH-1:0] I5;
    wire signed [DATA_WIDTH-1:0] I6;
    wire signed [DATA_WIDTH-1:0] I7;
    wire signed [DATA_WIDTH-1:0] I8;
    wire signed [DATA_WIDTH-1:0] Q1;
    wire signed [DATA_WIDTH-1:0] Q2;
    wire signed [DATA_WIDTH-1:0] Q3;
    wire signed [DATA_WIDTH-1:0] Q4;
    wire signed [DATA_WIDTH-1:0] Q5;
    wire signed [DATA_WIDTH-1:0] Q6;
    wire signed [DATA_WIDTH-1:0] Q7;
    wire signed [DATA_WIDTH-1:0] Q8;
    
    wire signed [DATA_WIDTH-1:0] I1_corr;
    wire signed [DATA_WIDTH-1:0] I2_corr;
    wire signed [DATA_WIDTH-1:0] I3_corr;
    wire signed [DATA_WIDTH-1:0] I4_corr;
    wire signed [DATA_WIDTH-1:0] I5_corr;
    wire signed [DATA_WIDTH-1:0] I6_corr;
    wire signed [DATA_WIDTH-1:0] I7_corr;
    wire signed [DATA_WIDTH-1:0] I8_corr;
    wire signed [DATA_WIDTH-1:0] Q1_corr;
    wire signed [DATA_WIDTH-1:0] Q2_corr;
    wire signed [DATA_WIDTH-1:0] Q3_corr;
    wire signed [DATA_WIDTH-1:0] Q4_corr;
    wire signed [DATA_WIDTH-1:0] Q5_corr;
    wire signed [DATA_WIDTH-1:0] Q6_corr;
    wire signed [DATA_WIDTH-1:0] Q7_corr;
    wire signed [DATA_WIDTH-1:0] Q8_corr;
    
    wire CIR_start;
    wire Payload_start;
    wire CIR_last;
    wire Payload_last;
    
    wire [DATA_WIDTH*8-1:0] CIR_I_tdata_0;
    wire [DATA_WIDTH*8-1:0] CIR_Q_tdata_0;
    wire [DATA_WIDTH*8-1:0] Payload_I;
    wire [DATA_WIDTH*8-1:0] Payload_Q;
    
    Derotate_p8 #(.DATA_WIDTH(DATA_WIDTH), .SHIFT(2)) Derot_p8_14 (
        .I(I_tdata),
        .Q(Q_tdata),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I5(I5),
        .I6(I6),
        .I7(I7),
        .I8(I8),
        .Q1(Q1),
        .Q2(Q2),
        .Q3(Q3),
        .Q4(Q4),
        .Q5(Q5),
        .Q6(Q6),
        .Q7(Q7),
        .Q8(Q8)
    );
 
     Derotate_p8 #(.DATA_WIDTH(DATA_WIDTH), .SHIFT(2)) Derot_p8_corr_14 (
        .I(I_tdata),
        .Q(Q_tdata),
        .I1(I1_corr),
        .I2(I2_corr),
        .I3(I3_corr),
        .I4(I4_corr),
        .I5(I5_corr),
        .I6(I6_corr),
        .I7(I7_corr),
        .I8(I8_corr),
        .Q1(Q1_corr),
        .Q2(Q2_corr),
        .Q3(Q3_corr),
        .Q4(Q4_corr),
        .Q5(Q5_corr),
        .Q6(Q6_corr),
        .Q7(Q7_corr),
        .Q8(Q8_corr)
    );   

    BD_Detect #(
        .DATA_WIDTH(DATA_WIDTH),
        .N_CORR_BITS(14)
    ) BD_detect (
        .en(en & i_valid & ~Payload_start), // kai 05182025
        .clk(clk),
        .rst(rst_self),
        .I1(I1_corr),
        .I2(I2_corr),
        .I3(I3_corr),
        .I4(I4_corr),
        .I5(I5_corr),
        .I6(I6_corr),
        .I7(I7_corr),
        .I8(I8_corr),
        .Q1(Q1_corr),
        .Q2(Q2_corr),
        .Q3(Q3_corr),
        .Q4(Q4_corr),
        .Q5(Q5_corr),
        .Q6(Q6_corr),
        .Q7(Q7_corr),
        .Q8(Q8_corr),
        .Pr_min(Pr_min),
        .BAC_TH(BAC_TH), 
        .NAC_SHIFT(NAC_SHIFT),
        .NAC_CC(NAC_CC),
        .BAC_CC(BAC_CC),
        .PD_BD_Delay(PD_BD_Delay),
        .PD_FLAG(PD_est),
        .BD_FLAG(BD_est),
        .NAC_L_Debug(NAC_L_Debug),
        .NAC_R_Debug(NAC_R_Debug),
        .BAC_L_Debug(BAC_L_Debug)
    );

    GACE_top #(.DATA_WIDTH(DATA_WIDTH)) GACE (
        .en(GACE_en), 
        .clk(clk),
        .rst(rst_self),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I5(I5),
        .I6(I6),
        .I7(I7),
        .I8(I8),
        .Q1(Q1),
        .Q2(Q2),
        .Q3(Q3),
        .Q4(Q4),
        .Q5(Q5),
        .Q6(Q6),
        .Q7(Q7),
        .Q8(Q8),
        .cnt_init(BAC_CC),
        .CIR_I(CIR_I_tdata_0),
        .CIR_Q(CIR_Q_tdata_0),
        .start(CIR_start),
        .last(CIR_last)
    );
    
    Payload_extract #(.DATA_WIDTH(DATA_WIDTH)) Payload (
        .clk(clk),
        .rst(rst),
        .start_collect(GACE_en),
        .cir_tx_last(CIR_last),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I5(I5),
        .I6(I6),
        .I7(I7),
        .I8(I8),
        .Q1(Q1),
        .Q2(Q2),
        .Q3(Q3),
        .Q4(Q4),
        .Q5(Q5),
        .Q6(Q6),
        .Q7(Q7),
        .Q8(Q8),
        .Payload_I_out(Payload_I),
        .Payload_Q_out(Payload_Q),
        .o_valid(Payload_start),
        .o_last(Payload_last)
    );

//    Delay_1 #(.DATA_WIDTH(1)) D_start (
//        .clk(clk),
//        .rst(rst),
//        .in(CIR_start),
//        .out(start_last_cc)
//    );

    assign CIR_I_tdata = (Payload_start == 1)? Payload_I : CIR_I_tdata_0;
    assign CIR_Q_tdata = (Payload_start == 1)? Payload_Q : CIR_Q_tdata_0;
    
    assign CIR_I_tvalid = CIR_start || Payload_start;
    assign CIR_Q_tvalid = CIR_start || Payload_start;
    assign CIR_I_tlast = Payload_last;         // added by Kai 04/22/2025
    assign CIR_Q_tlast = Payload_last;         // added by Kai 04/22/2025
    assign I_tready = 1'b1;
    assign Q_tready = 1'b1;
    
    initial begin
        GACE_en <= 0;    
        rst_self <= 0;
        shift_cnt <= 0;
    end
    
    // BD_detect --> BD_FLAG, 
    // CIR_I_tready, CIR_Q_tready
    always@(posedge clk, posedge rst) begin
        if (rst) begin
            rst_self <= 1;
            shift_cnt <= 0;
            GACE_en <= 0;
        end
        else if (en) begin
            if (rst_self) begin
                rst_self <= 0;
                GACE_en <= 0;
            end
            else if (BD_FLAG) begin
                if (shift_cnt == SHIFT_CC) begin
                    shift_cnt <= 0;
                    // Kai 05/26/2024
                    if (CIR_I_tready & CIR_Q_tready) begin
                        GACE_en <= 1;
                    end else begin
                        rst_self <= 1;  // discard this frame if the next block not ready 
                    end
                end else 
                    shift_cnt <= shift_cnt + 1;
            end
//            if (start_last_cc == 1 && CIR_start == 0) 
//                rst_self <= 1; // when CIR stopped  //// kai: this also resets the BD block. 
//            end
            if (CIR_last == 1) 
                rst_self <= 1; // kai 05182025: resets PD and BD 
            end
        else ;
    end

endmodule
