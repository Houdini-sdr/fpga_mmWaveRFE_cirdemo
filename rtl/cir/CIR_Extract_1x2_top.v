/**
 * Module     : CIR_Extract_1x2_top
 * Description: CIR Extraction With Package/Boundary Detection
 * Author     : Wuqiong Zhao (me@wqzhao.org)
 *
 * Created    : 2023-07-05
 * Updated    : 2023-09-06
 *
 */

module CIR_Extract_1x2_top #(
    parameter DATA_WIDTH = 16 // <--- DO NOT CHANGE
) (
    input  en,
    input  clk,
    input  rst_n,
    // -- Rx 1 -- //
    // Input FIFO
    input  [DATA_WIDTH*8-1:0] I1_tdata,     // input I data before derotating
    input  [DATA_WIDTH*8-1:0] Q1_tdata,     // input Q data before derotating
    input  I1_tvalid,
    input  Q1_tvalid,
    output I1_tready,
    output Q1_tready,
    // Output FIFOs
    output [DATA_WIDTH*8-1:0] CIR_I1_tdata, // FIFO output for CIR (I)
    output [DATA_WIDTH*8-1:0] CIR_Q1_tdata, // FIFO output for CIR (Q)
    output CIR_I1_tvalid,
    output CIR_Q1_tvalid,
    input  CIR_I1_tready,                   // (ignored)
    input  CIR_Q1_tready,                   // (ignored)
    output CIR_I1_tlast,
    output CIR_Q1_tlast,
    output start,                          // the start of CIR output into FIFO
    output last,                           // the last element of CIR output
    // -- Rx 2 -- //
    // Input FIFO
    input  [DATA_WIDTH*8-1:0] I2_tdata,     // input I data before derotating
    input  [DATA_WIDTH*8-1:0] Q2_tdata,     // input Q data before derotating
    input  I2_tvalid,
    input  Q2_tvalid,
    output I2_tready,
    output Q2_tready,
    // Output FIFOs
    output [DATA_WIDTH*8-1:0] CIR_I2_tdata, // FIFO output for CIR (I)
    output [DATA_WIDTH*8-1:0] CIR_Q2_tdata, // FIFO output for CIR (Q)
    output CIR_I2_tvalid,
    output CIR_Q2_tvalid,
    input  CIR_I2_tready,                   // (ignored)
    input  CIR_Q2_tready,                   // (ignored)
    output CIR_I2_tlast,
    output CIR_Q2_tlast,

    // AXI Settings
    input  [3:0] NAC_SHIFT,                // the shift threshold in PD
    input  [3:0] NAC_CC,                   // number of clocks used in PD
    input  [3:0] BAC_CC,                   // number of clocks used in BD
    input  [3:0] SHIFT_CC,                 // shift CIR (i.e. delat GACE_en)
    input        BYPASS_PD,                // bypass package detection
    input  PD_real,
    input  BD_real,
    output PD_FLAG,                        // package detected
    output BD_FLAG,                        // boundary detected
    output reg GACE_en                     // start of CIR calculation
);

    wire rst;
    wire i1_valid, i2_valid;
    assign i1_valid = I1_tvalid & Q1_tvalid;
    assign i2_valid = I2_tvalid & Q2_tvalid;
    assign rst = ~rst_n;

    wire PD_est, BD_est;
    
    assign PD_FLAG = BYPASS_PD ? PD_real : PD_est;
    assign BD_FLAG = BYPASS_PD ? BD_real : BD_est;

    reg rst_self;
    reg [3:0] shift_cnt;
    wire start_last_cc;
    
    wire signed [DATA_WIDTH-1:0] I1_1;
    wire signed [DATA_WIDTH-1:0] I1_2;
    wire signed [DATA_WIDTH-1:0] I1_3;
    wire signed [DATA_WIDTH-1:0] I1_4;
    wire signed [DATA_WIDTH-1:0] I1_5;
    wire signed [DATA_WIDTH-1:0] I1_6;
    wire signed [DATA_WIDTH-1:0] I1_7;
    wire signed [DATA_WIDTH-1:0] I1_8;
    wire signed [DATA_WIDTH-1:0] Q1_1;
    wire signed [DATA_WIDTH-1:0] Q1_2;
    wire signed [DATA_WIDTH-1:0] Q1_3;
    wire signed [DATA_WIDTH-1:0] Q1_4;
    wire signed [DATA_WIDTH-1:0] Q1_5;
    wire signed [DATA_WIDTH-1:0] Q1_6;
    wire signed [DATA_WIDTH-1:0] Q1_7;
    wire signed [DATA_WIDTH-1:0] Q1_8;
    wire signed [DATA_WIDTH-1:0] I2_1;
    wire signed [DATA_WIDTH-1:0] I2_2;
    wire signed [DATA_WIDTH-1:0] I2_3;
    wire signed [DATA_WIDTH-1:0] I2_4;
    wire signed [DATA_WIDTH-1:0] I2_5;
    wire signed [DATA_WIDTH-1:0] I2_6;
    wire signed [DATA_WIDTH-1:0] I2_7;
    wire signed [DATA_WIDTH-1:0] I2_8;
    wire signed [DATA_WIDTH-1:0] Q2_1;
    wire signed [DATA_WIDTH-1:0] Q2_2;
    wire signed [DATA_WIDTH-1:0] Q2_3;
    wire signed [DATA_WIDTH-1:0] Q2_4;
    wire signed [DATA_WIDTH-1:0] Q2_5;
    wire signed [DATA_WIDTH-1:0] Q2_6;  
    wire signed [DATA_WIDTH-1:0] Q2_7;
    wire signed [DATA_WIDTH-1:0] Q2_8;

    Derotate_p8 #(.DATA_WIDTH(DATA_WIDTH)) Derot_p8_1 (
        .I(I1_tdata),
        .Q(Q1_tdata),
        .I1(I1_1),
        .I2(I1_2),
        .I3(I1_3),
        .I4(I1_4),
        .I5(I1_5),
        .I6(I1_6),
        .I7(I1_7),
        .I8(I1_8),
        .Q1(Q1_1),
        .Q2(Q1_2),
        .Q3(Q1_3),
        .Q4(Q1_4),
        .Q5(Q1_5),
        .Q6(Q1_6),
        .Q7(Q1_7),
        .Q8(Q1_8)
    );
    Derotate_p8 #(.DATA_WIDTH(DATA_WIDTH)) Derot_p8_2 (
        .I(I2_tdata),
        .Q(Q2_tdata),
        .I1(I2_1),
        .I2(I2_2),
        .I3(I2_3),
        .I4(I2_4),
        .I5(I2_5),
        .I6(I2_6),
        .I7(I2_7),
        .I8(I2_8),
        .Q1(Q2_1),
        .Q2(Q2_2),
        .Q3(Q2_3),
        .Q4(Q2_4),
        .Q5(Q2_5),
        .Q6(Q2_6),
        .Q7(Q2_7),
        .Q8(Q2_8)
    );

    BD_Detect #(.DATA_WIDTH(DATA_WIDTH)) BD_detect (
        .en(en & i1_valid),
        .clk(clk),
        .rst(rst_self),
        .I1(I1_1),
        .I2(I1_2),
        .I3(I1_3),
        .I4(I1_4),
        .I5(I1_5),
        .I6(I1_6),
        .I7(I1_7),
        .I8(I1_8),
        .Q1(Q1_1),
        .Q2(Q1_2),
        .Q3(Q1_3),
        .Q4(Q1_4),
        .Q5(Q1_5),
        .Q6(Q1_6),
        .Q7(Q1_7),
        .Q8(Q1_8),
        .NAC_SHIFT(NAC_SHIFT),
        .NAC_CC(NAC_CC),
        .BAC_CC(BAC_CC),
        .PD_FLAG(PD_est),
        .BD_FLAG(BD_est)
    );

    GACE_top #(.DATA_WIDTH(DATA_WIDTH)) GACE_1 (
        .en(GACE_en),
        .clk(clk),
        .rst(rst_self),
        .I1(I1_1),
        .I2(I1_2),
        .I3(I1_3),
        .I4(I1_4),
        .I5(I1_5),
        .I6(I1_6),
        .I7(I1_7),
        .I8(I1_8),
        .Q1(Q1_1),
        .Q2(Q1_2),
        .Q3(Q1_3),
        .Q4(Q1_4),
        .Q5(Q1_5),
        .Q6(Q1_6),
        .Q7(Q1_7),
        .Q8(Q1_8),
        .cnt_init(BAC_CC),
        .CIR_I(CIR_I1_tdata),
        .CIR_Q(CIR_Q1_tdata),
        .start(start),
        .last(last)
    );
    GACE_top #(.DATA_WIDTH(DATA_WIDTH)) GACE_2 (
        .en(GACE_en),
        .clk(clk),
        .rst(rst_self),
        .I1(I2_1),
        .I2(I2_2),
        .I3(I2_3),
        .I4(I2_4),
        .I5(I2_5),
        .I6(I2_6),
        .I7(I2_7),
        .I8(I2_8),
        .Q1(Q2_1),
        .Q2(Q2_2),
        .Q3(Q2_3),
        .Q4(Q2_4),
        .Q5(Q2_5),
        .Q6(Q2_6),
        .Q7(Q2_7),
        .Q8(Q2_8),
        .cnt_init(BAC_CC),
        .CIR_I(CIR_I2_tdata),
        .CIR_Q(CIR_Q2_tdata),
        .start(),
        .last()
    );

    Delay_1 #(.DATA_WIDTH(1)) D_start (
        .clk(clk),
        .rst(rst),
        .in(start),
        .out(start_last_cc)
    );

    assign CIR_I1_tvalid = start;
    assign CIR_Q1_tvalid = start;
    assign CIR_I2_tvalid = start;
    assign CIR_Q2_tvalid = start;

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
                    GACE_en <= 1;
                end
                else shift_cnt <= shift_cnt + 1;
            end
            if (start_last_cc == 1 && start == 0) rst_self <= 1; // when CIR stopped
        end
        else ;
    end

    assign I1_tready = 1'b1;
    assign Q1_tready = 1'b1;
    assign I2_tready = 1'b1;
    assign Q2_tready = 1'b1;

    assign CIR_I1_tlast = last;
    assign CIR_Q1_tlast = last;
    assign CIR_I2_tlast = last;
    assign CIR_Q2_tlast = last;

endmodule
