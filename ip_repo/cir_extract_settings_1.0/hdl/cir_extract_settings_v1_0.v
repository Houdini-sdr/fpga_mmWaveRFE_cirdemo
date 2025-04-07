
`timescale 1 ns / 1 ps

	module cir_extract_settings_v1_0 #
	(
		// Users to add parameters here
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
        output wire [3:0] NAC_SHIFT, // S0
        output wire [15:0] NAC_CC, // S1
        output wire [15:0] BAC_CC, // S2
        output wire [3:0] SHIFT_CC, // S3
        output wire       BYPASS_PD, // S4
        output wire [15:0] REAL_PD_SHIFT, // S4
        output wire [3:0] NOISE_SHIFT, // S5
        output wire [15:0] AMPLITUDE, // S6
        output wire [15:0] DELAY, // S7
        output wire [15:0]  CIR_EN, // S8
        output wire [15:0] HEADER_PER_FRAME, // S9
        output wire [31:0] Pr_min, // S10
        output wire [7:0] PD_BD_Delay, // S11
		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	localparam ALL_BITS = 12 * 32;

	wire [31:0] S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11;
// Instantiation of Axi Bus Interface S00_AXI
	cir_extract_settings_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) cir_extract_settings_v1_0_S00_AXI_inst (
		.slv_reg0_output(S0),
		.slv_reg1_output(S1),
		.slv_reg2_output(S2),
		.slv_reg3_output(S3),
		.slv_reg4_output(S4),
		.slv_reg5_output(S5),
		.slv_reg6_output(S6),
		.slv_reg7_output(S7),
		.slv_reg8_output(S8),
		.slv_reg9_output(S9),
		.slv_reg10_output(S10),
		.slv_reg11_output(S11),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here       
     assign NAC_SHIFT = S0[3:0];
     assign NAC_CC = S1[15:0];
     assign BAC_CC = S2[15:0];
     assign SHIFT_CC = S3[3:0];
     assign BYPASS_PD = (S4[15:0] != 16'b0);
     assign REAL_PD_SHIFT = S4[15:0];
     assign NOISE_SHIFT = S5[3:0];
     assign AMPLITUDE = S6[15:0];
     assign DELAY = S7[15:0];
     assign CIR_EN = S8[15:0];
     assign HEADER_PER_FRAME = S9[15:0];
     assign Pr_min = S10[31:0];
     assign PD_BD_Delay = S11[7:0]; 
	// User logic ends

	endmodule
