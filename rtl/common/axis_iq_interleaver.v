`timescale 1ns / 1ps

module axis_iq_interleaver #(
    parameter SAMPLE_WIDTH = 16,
    parameter SAMPLES_PER_STREAM = 8
) (
    input  wire                                         aclk,
    input  wire                                         aresetn,

    input  wire [SAMPLES_PER_STREAM*SAMPLE_WIDTH-1:0]   s_axis_i_tdata,
    input  wire                                         s_axis_i_tvalid,
    output wire                                         s_axis_i_tready,

    input  wire [SAMPLES_PER_STREAM*SAMPLE_WIDTH-1:0]   s_axis_q_tdata,
    input  wire                                         s_axis_q_tvalid,
    output wire                                         s_axis_q_tready,

    output wire [2*SAMPLES_PER_STREAM*SAMPLE_WIDTH-1:0] m_axis_tdata,
    output wire                                         m_axis_tvalid,
    input  wire                                         m_axis_tready
);

    localparam INPUT_DATA_WIDTH = SAMPLES_PER_STREAM*SAMPLE_WIDTH;
    localparam OUTPUT_DATA_WIDTH = 2*SAMPLES_PER_STREAM*SAMPLE_WIDTH;
    localparam OUTPUT_KEEP_WIDTH = (OUTPUT_DATA_WIDTH+7)/8;

    reg [INPUT_DATA_WIDTH-1:0] i_axis_tdata_reg = {INPUT_DATA_WIDTH{1'b0}};
    reg                       i_axis_tvalid_reg = 1'b0;
    reg [INPUT_DATA_WIDTH-1:0] q_axis_tdata_reg = {INPUT_DATA_WIDTH{1'b0}};
    reg                       q_axis_tvalid_reg = 1'b0;

    wire [OUTPUT_DATA_WIDTH-1:0] pair_axis_tdata;
    wire                         pair_axis_tvalid;
    wire                         pair_axis_tready;
    wire                         pair_axis_fire;

    assign pair_axis_tvalid = i_axis_tvalid_reg & q_axis_tvalid_reg;
    assign pair_axis_fire = pair_axis_tvalid & pair_axis_tready;

    assign s_axis_i_tready = !i_axis_tvalid_reg || pair_axis_fire;
    assign s_axis_q_tready = !q_axis_tvalid_reg || pair_axis_fire;

    wire i_axis_accept = s_axis_i_tvalid & s_axis_i_tready;
    wire q_axis_accept = s_axis_q_tvalid & s_axis_q_tready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            i_axis_tdata_reg <= {INPUT_DATA_WIDTH{1'b0}};
            i_axis_tvalid_reg <= 1'b0;
            q_axis_tdata_reg <= {INPUT_DATA_WIDTH{1'b0}};
            q_axis_tvalid_reg <= 1'b0;
        end else begin
            if (pair_axis_fire) begin
                i_axis_tvalid_reg <= 1'b0;
                q_axis_tvalid_reg <= 1'b0;
            end

            if (i_axis_accept) begin
                i_axis_tdata_reg <= s_axis_i_tdata;
                i_axis_tvalid_reg <= 1'b1;
            end

            if (q_axis_accept) begin
                q_axis_tdata_reg <= s_axis_q_tdata;
                q_axis_tvalid_reg <= 1'b1;
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < SAMPLES_PER_STREAM; i = i + 1) begin : gen_interleave
            assign pair_axis_tdata[(2*i)*SAMPLE_WIDTH +: SAMPLE_WIDTH] =
                i_axis_tdata_reg[i*SAMPLE_WIDTH +: SAMPLE_WIDTH];
            assign pair_axis_tdata[(2*i+1)*SAMPLE_WIDTH +: SAMPLE_WIDTH] =
                q_axis_tdata_reg[i*SAMPLE_WIDTH +: SAMPLE_WIDTH];
        end
    endgenerate

    axis_register #(
        .DATA_WIDTH(OUTPUT_DATA_WIDTH),
        .KEEP_ENABLE(0),
        .KEEP_WIDTH(OUTPUT_KEEP_WIDTH),
        .LAST_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .REG_TYPE(2)
    ) output_register_inst (
        .clk(aclk),
        .rst(!aresetn),
        .s_axis_tdata(pair_axis_tdata),
        .s_axis_tkeep({OUTPUT_KEEP_WIDTH{1'b1}}),
        .s_axis_tvalid(pair_axis_tvalid),
        .s_axis_tready(pair_axis_tready),
        .s_axis_tlast(1'b0),
        .s_axis_tid(8'd0),
        .s_axis_tdest(8'd0),
        .s_axis_tuser(1'b0),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(),
        .m_axis_tid(),
        .m_axis_tdest(),
        .m_axis_tuser()
    );

endmodule
