
`timescale 1 ns / 1 ps

	module pam_controller_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of ID for for write address, write data, read address and read data
		parameter integer C_S_AXI_ID_WIDTH	= 1,
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 11,
		// Width of optional user defined signal in write address channel
		parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
		// Width of optional user defined signal in read address channel
		parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
		// Width of optional user defined signal in write data channel
		parameter integer C_S_AXI_WUSER_WIDTH	= 0,
		// Width of optional user defined signal in read data channel
		parameter integer C_S_AXI_RUSER_WIDTH	= 0,
		// Width of optional user defined signal in write response channel
		parameter integer C_S_AXI_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here
        input wire cmd_clk2x,   // 236 MHz
        input wire beamscan_en,
        input wire cmd_trig,
        output wire cmd_out_1,          
        output wire cmd_out_2,
        output wire cmd_out_3,          
        output wire cmd_out_4,        
        output wire cmd_done_1,
        output wire cmd_done_2,
        output wire cmd_done_3,
        output wire cmd_done_4,        
        
        // Kai 04/21/2025  the sector IDs are routed out to other blocks. 
        output wire [6:0] sector_1,
        output wire [6:0] sector_2,
        output wire [6:0] sector_3,
        output wire [6:0] sector_4,
        
        // Kai: These signals are for debugging use.
        output wire trig_start_1,
        output wire trig_end_1,
        output wire [15:0] seq_end_addr_1,
        output wire [15:0] seq_addr_1,
        output reg [94:0] cmd_data_1,
        
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write Address ID
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
		// Write address
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_AWBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		input wire  S_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		input wire [3 : 0] S_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each
    // write transaction.
		input wire [3 : 0] S_AXI_AWQOS,
		// Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
		input wire [3 : 0] S_AXI_AWREGION,
		// Optional User-defined signal in the write address channel.
		input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] S_AXI_AWUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
		output wire  S_AXI_AWREADY,
		// Write Data
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write last. This signal indicates the last transfer
    // in a write burst.
		input wire  S_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		input wire [C_S_AXI_WUSER_WIDTH-1 : 0] S_AXI_WUSER,
		// Write valid. This signal indicates that valid write
    // data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    // can accept the write data.
		output wire  S_AXI_WREADY,
		// Response ID tag. This signal is the ID tag of the
    // write response.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
		// Write response. This signal indicates the status
    // of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Optional User-defined signal in the write response channel.
		output wire [C_S_AXI_BUSER_WIDTH-1 : 0] S_AXI_BUSER,
		// Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    // can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address ID. This signal is the identification
    // tag for the read address group of signals.
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
		// Read address. This signal indicates the initial
    // address of a read burst transaction.
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_ARBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		input wire  S_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		input wire [3 : 0] S_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each
    // read transaction.
		input wire [3 : 0] S_AXI_ARQOS,
		// Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
		input wire [3 : 0] S_AXI_ARREGION,
		// Optional User-defined signal in the read address channel.
		input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] S_AXI_ARUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
		output wire  S_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
		// Read Data
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of
    // the read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read last. This signal indicates the last transfer
    // in a read burst.
		output wire  S_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
		output wire [C_S_AXI_RUSER_WIDTH-1 : 0] S_AXI_RUSER,
		// Read valid. This signal indicates that the channel
    // is signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    // accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4FULL signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg [C_S_AXI_BUSER_WIDTH-1 : 0] 	axi_buser;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rlast;
	reg [C_S_AXI_RUSER_WIDTH-1 : 0] 	axi_ruser;
	reg  	axi_rvalid;
	// aw_wrap_en determines wrap boundary and enables wrapping
	wire aw_wrap_en;
	// ar_wrap_en determines wrap boundary and enables wrapping
	wire ar_wrap_en;
	// aw_wrap_size is the size of the write transfer, the
	// write address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  aw_wrap_size ; 
	// ar_wrap_size is the size of the read transfer, the
	// read address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  ar_wrap_size ; 
	// The axi_awv_awr_flag flag marks the presence of write address valid
	reg axi_awv_awr_flag;
	//The axi_arv_arr_flag flag marks the presence of read address valid
	reg axi_arv_arr_flag; 
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;
	//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	reg [7:0] axi_arlen_cntr;
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
	localparam integer OPT_MEM_ADDR_BITS = 8;
	localparam integer USER_NUM_MEM = 1;
	//----------------------------------------------
	//-- Signals for user logic memory space example
	//------------------------------------------------
	wire [OPT_MEM_ADDR_BITS:0] mem_address;
	wire [USER_NUM_MEM-1:0] mem_select;
	reg [C_S_AXI_DATA_WIDTH-1:0] mem_data_out[0 : USER_NUM_MEM-1];

	genvar i;
	genvar j;
	genvar mem_byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BUSER	= axi_buser;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RLAST	= axi_rlast;
	assign S_AXI_RUSER	= axi_ruser;
	assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_RID = S_AXI_ARID;
	assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

	// Implement axi_awready generation

	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      axi_awv_awr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          // slave is ready to accept an address and
	          // associated control signals
	          axi_awready <= 1'b1;
	          axi_awv_awr_flag  <= 1'b1; 
	          // used for generation of bresp() and bvalid
	        end
	      else if (S_AXI_WLAST && axi_wready)          
	      // preparing to accept next address after current write burst tx completion
	        begin
	          axi_awv_awr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_awaddr latching

	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching 
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;     
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase              
	        end
	    end 
	end       
	// Implement axi_wready generation

	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	        begin
	          // slave can accept the write data
	          axi_wready <= 1'b1;
	        end
	      //else if (~axi_awv_awr_flag)
	      else if (S_AXI_WLAST && axi_wready)
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       
	// Implement write response logic generation

	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid <= 0;
	      axi_bresp <= 2'b0;
	      axi_buser <= 0;
	    end 
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST )
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	          //check if bready is asserted while bvalid is high) 
	          //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	 end   
	// Implement axi_arready generation

	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_arv_arr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          axi_arready <= 1'b1;
	          axi_arv_arr_flag <= 1'b1;
	        end
	      else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen)
	      // preparing to accept next address after current read completion
	        begin
	          axi_arv_arr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_araddr latching

	//This process is used to latch the address when both 
	//S_AXI_ARVALID and S_AXI_RVALID are valid. 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_araddr <= 0;
	      axi_arlen_cntr <= 0;
	      axi_arburst <= 0;
	      axi_arlen <= 0;
	      axi_rlast <= 1'b0;
	      axi_ruser <= 0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	        begin
	          // address latching 
	          axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
	          axi_arburst <= S_AXI_ARBURST; 
	          axi_arlen <= S_AXI_ARLEN;     
	          // start address of transfer
	          axi_arlen_cntr <= 0;
	          axi_rlast <= 1'b0;
	        end   
	      else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
	        begin
	         
	          axi_arlen_cntr <= axi_arlen_cntr + 1;
	          axi_rlast <= 1'b0;
	        
	          case (axi_arburst)
	            2'b00: // fixed burst
	             // The read address for all the beats in the transaction are fixed
	              begin
	                axi_araddr       <= axi_araddr;        
	                //for arsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The read address for all the beats in the transaction are increments by awsize
	              begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The read address wraps when the address reaches wrap boundary 
	              if (ar_wrap_en) 
	                begin
	                  axi_araddr <= (axi_araddr - ar_wrap_size); 
	                end
	              else 
	                begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                //for arsize = 4 bytes (010)
	              end
	          endcase              
	        end
	      else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
	        begin
	          axi_rlast <= 1'b1;
	        end          
	      else if (S_AXI_RREADY)   
	        begin
	          axi_rlast <= 1'b0;
	        end          
	    end 
	end       
	// Implement axi_arvalid generation

	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arv_arr_flag && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	          // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end            
	    end
	end    
	// ------------------------------------------
	// -- Example code to access user logic memory region
	// ------------------------------------------

	generate
	  if (USER_NUM_MEM >= 1)
	    begin
	      assign mem_select  = 1;
	      assign mem_address = (axi_arv_arr_flag? axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:(axi_awv_awr_flag? axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:0));
	    end
	endgenerate
	     
	// implement Block RAM(s)
	generate 
	  for(i=0; i<= USER_NUM_MEM-1; i=i+1)
	    begin:BRAM_GEN
	      wire mem_rden;
	      wire mem_wren;
	
	      assign mem_wren = axi_wready && S_AXI_WVALID ;
	
	      assign mem_rden = axi_arv_arr_flag ; //& ~axi_rvalid
	     
	      for(mem_byte_index=0; mem_byte_index<= (C_S_AXI_DATA_WIDTH/8-1); mem_byte_index=mem_byte_index+1)
	      begin:BYTE_BRAM_GEN
	        wire [8-1:0] data_in ;
	        wire [8-1:0] data_out;
	        reg  [8-1:0] byte_ram [0 : 511]; // Kai: 11/26/2024 doubled the size
	        integer j;
	     
	        //assigning 8 bit data
	        assign data_in  = S_AXI_WDATA[(mem_byte_index*8+7) -: 8];
	        assign data_out = byte_ram[mem_address];
	     
	        always @( posedge S_AXI_ACLK )
	        begin
	          if (mem_wren && S_AXI_WSTRB[mem_byte_index])
	            begin
	              byte_ram[mem_address] <= data_in;
	            end   
	        end    
	      
	        always @( posedge S_AXI_ACLK )
	        begin
	          if (mem_rden)
	            begin
	              mem_data_out[i][(mem_byte_index*8+7) -: 8] <= data_out;
	            end   
	        end    
	               
	    end
	  end       
	endgenerate
	//Output register or memory read data

	always @( mem_data_out, axi_rvalid)
	begin
	  if (axi_rvalid) 
	    begin
	      // Read address mux
	      axi_rdata <= mem_data_out[0];
	    end   
	  else
	    begin
	      axi_rdata <= 32'h00000000;
	    end       
	end    

	// Add user logic here 
	wire [7:0] cmd_len;
	wire [3:0] chan_sel;   // 4 channels supported max
	wire [71:0] cmd_payload;
	
	wire [8-1:0] memout_1a, memout_1b;
	wire [8-1:0] memout_2a, memout_2b;
	wire [8-1:0] memout_3a, memout_3b;
	wire [8-1:0] memout_4a, memout_4b;
		
	wire [16-1:0] time_gap_1, time_gap_2, time_gap_3, time_gap_4;
	wire [16-1:0] seq_end_addr_2, seq_end_addr_3, seq_end_addr_4;
	// seq_end_addr_1
	wire [11:0] crc_addr_1, crc_addr_2, crc_addr_3, crc_addr_4;
	wire [16-1:0] seq_addr_2, seq_addr_3, seq_addr_4;
	// seq_addr_1
	
	localparam SEQ_ADDR_OFFSET = 8;
	localparam CMD_SEQ_LENGTH = 128;
	
	// BYTE_BRAM_GEN[byte_index];  byte_ram[row_address]
	assign cmd_len = BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[0];
	assign chan_sel = BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[0][3:0];
	assign cmd_payload = {BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[0], 
	   BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[1], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[1], BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[1], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[1],
	   BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[2], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[2], BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[2], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[2]};
	
	assign time_gap_1 = {BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[4], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[4]};
	assign time_gap_2 = {BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[4], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[4]};
	assign time_gap_3 = {BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[5], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[5]};
	assign time_gap_4 = {BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[5], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[5]};
	
	assign seq_end_addr_1 = {BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[6], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[6]};
	assign seq_end_addr_2 = {BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[6], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[6]};
	assign seq_end_addr_3 = {BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[7], BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[7]};
	assign seq_end_addr_4 = {BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[7], BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[7]};
	
	assign memout_1a = BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[seq_addr_1[8:0] + SEQ_ADDR_OFFSET];
	assign memout_1b = BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[seq_addr_1[8:0] + SEQ_ADDR_OFFSET];
	assign memout_2a = BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[seq_addr_2[8:0] + SEQ_ADDR_OFFSET];
	assign memout_2b = BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[seq_addr_2[8:0] + SEQ_ADDR_OFFSET];
	assign memout_3a = BRAM_GEN[0].BYTE_BRAM_GEN[0].byte_ram[seq_addr_3[8:0] + SEQ_ADDR_OFFSET + CMD_SEQ_LENGTH];
	assign memout_3b = BRAM_GEN[0].BYTE_BRAM_GEN[1].byte_ram[seq_addr_3[8:0] + SEQ_ADDR_OFFSET + CMD_SEQ_LENGTH];
	assign memout_4a = BRAM_GEN[0].BYTE_BRAM_GEN[2].byte_ram[seq_addr_4[8:0] + SEQ_ADDR_OFFSET + CMD_SEQ_LENGTH];
	assign memout_4b = BRAM_GEN[0].BYTE_BRAM_GEN[3].byte_ram[seq_addr_4[8:0] + SEQ_ADDR_OFFSET + CMD_SEQ_LENGTH];
		
	localparam BEAMSCAN_CMD_LEN = 59;  // Manchester Encoder seq module manchester_encoder
	
	reg [15:0] 	crcarray [0:4095];

    initial begin
        $readmemh("crc.mem",crcarray);
    end

    wire [23:0] pre_1;
    wire [5:0]  pre_2;
    assign pre_1 = 24'h00e2e9;
    assign pre_2 = 6'h10;   
    
    //memout has 1 clock delay from seq_addr
    //need to use memout to get data from crc ram
    //memout bit 11 = tx/rx 1 for tx, 0 for rx
    //memout bit 10:4 = sector
    //memout bit 3:0 = gain
    //sector and gain must output LSB first
    wire [3:0] gain_1, gain_2, gain_3, gain_4;
    //wire [6:0] sector_1, sector_2, sector_3, sector_4; // Kai 04/21/2025: moved to the port definition
    reg [94:0] cmd_data_2, cmd_data_3, cmd_data_4;
    //cmd_data_1 
    
    assign gain_1 = {memout_1a[0], memout_1a[1], memout_1a[2], memout_1a[3]};
    assign gain_2 = {memout_2a[0], memout_2a[1], memout_2a[2], memout_2a[3]};
    assign gain_3 = {memout_3a[0], memout_3a[1], memout_3a[2], memout_3a[3]};
    assign gain_4 = {memout_4a[0], memout_4a[1], memout_4a[2], memout_4a[3]};
    
    assign sector_1 = {memout_1b[0], memout_1b[1], memout_1b[2], memout_1b[3], memout_1b[4], memout_1b[5], memout_1b[6]};
    assign sector_2 = {memout_2b[0], memout_2b[1], memout_2b[2], memout_2b[3], memout_2b[4], memout_2b[5], memout_2b[6]};
    assign sector_3 = {memout_3b[0], memout_3b[1], memout_3b[2], memout_3b[3], memout_3b[4], memout_3b[5], memout_3b[6]};
    assign sector_4 = {memout_4b[0], memout_4b[1], memout_4b[2], memout_4b[3], memout_4b[4], memout_4b[5], memout_4b[6]};
        
    assign tr_1 =  memout_1b[7];    
    assign tr_2 =  memout_2b[7];
    assign tr_3 =  memout_3b[7];    
    assign tr_4 =  memout_4b[7];
        
    assign crc_addr_1 = {memout_1b[7:0], memout_1a[3:0]};
    assign crc_addr_2 = {memout_2b[7:0], memout_2a[3:0]};
    assign crc_addr_3 = {memout_3b[7:0], memout_3a[3:0]};
    assign crc_addr_4 = {memout_4b[7:0], memout_4a[3:0]};
    
    reg clk1x = 0;
    always @(posedge cmd_clk2x) begin
        clk1x <= ~clk1x;
    end
   
    // Must use cmd_clk to avoid cross-clock domain timing issue. 
    // Ideally XPM_CDC block should be added. 
    always @ (posedge cmd_clk2x) begin
        if (cmd_trig == 1'b1) begin
            cmd_data_1 <= {pre_1, cmd_payload[70:0]}; // total 95 bits. 
            cmd_data_2 <= {pre_1, cmd_payload[70:0]}; // total 95 bits. 
            cmd_data_3 <= {pre_1, cmd_payload[70:0]}; // total 95 bits. 
            cmd_data_4 <= {pre_1, cmd_payload[70:0]}; // total 95 bits. 
        end else if (beamscan_en == 1'b1) begin
            cmd_data_1 <= {pre_1, ~tr_1, tr_1, pre_2, sector_1[6:0], gain_1[3:0], crcarray[crc_addr_1], 36'h0}; // total length should be 95 bits
            cmd_data_2 <= {pre_1, ~tr_2, tr_2, pre_2, sector_2[6:0], gain_2[3:0], crcarray[crc_addr_2], 36'h0}; // total length should be 95 bits
            cmd_data_3 <= {pre_1, ~tr_3, tr_3, pre_2, sector_3[6:0], gain_3[3:0], crcarray[crc_addr_3], 36'h0}; // total length should be 95 bits
            cmd_data_4 <= {pre_1, ~tr_4, tr_4, pre_2, sector_4[6:0], gain_4[3:0], crcarray[crc_addr_4], 36'h0}; // total length should be 95 bits
        end else begin
            cmd_data_1 <= 95'h0;
            cmd_data_2 <= 95'h0;
            cmd_data_3 <= 95'h0;
            cmd_data_4 <= 95'h0;            
        end
    end
    
    wire [7:0] cmd_len_1; 
    wire [7:0] cmd_len_2; 
    wire [7:0] cmd_len_3; 
    wire [7:0] cmd_len_4; 
        
    wire trig_1, trig_2, trig_3, trig_4;
        
    assign cmd_len_1 = (cmd_trig == 1'b1 && chan_sel[0] == 1'b1) ? cmd_len : BEAMSCAN_CMD_LEN;
    assign cmd_len_2 = (cmd_trig == 1'b1 && chan_sel[1] == 1'b1) ? cmd_len : BEAMSCAN_CMD_LEN;
    assign cmd_len_3 = (cmd_trig == 1'b1 && chan_sel[2] == 1'b1) ? cmd_len : BEAMSCAN_CMD_LEN;
    assign cmd_len_4 = (cmd_trig == 1'b1 && chan_sel[3] == 1'b1) ? cmd_len : BEAMSCAN_CMD_LEN;
        
    assign trig_1 = (cmd_trig == 1'b1 && chan_sel[0] == 1'b1) ? 1'b1 : trig_scan_1; 
    assign trig_2 = (cmd_trig == 1'b1 && chan_sel[1] == 1'b1) ? 1'b1 : trig_scan_2; 
    assign trig_3 = (cmd_trig == 1'b1 && chan_sel[2] == 1'b1) ? 1'b1 : trig_scan_3; 
    assign trig_4 = (cmd_trig == 1'b1 && chan_sel[3] == 1'b1) ? 1'b1 : trig_scan_4; 
        
    sequence_ctr u_seq_ctr_1
    (
       .ctr_en           (beamscan_en),
       .clk              (clk1x),
       .i_seq_end_addr   (seq_end_addr_1),
       .i_time_gap       (time_gap_1),
       .o_seq_addr         (seq_addr_1),
       .o_manchester_wren  (trig_scan_1)
    );

    cmd_serializer u_cmd_serializer_1
    (
        .i_clock    (clk1x),
        .i_reset    (reset),
        .i_trigger  (trig_1),
        .i_cmd_len  (cmd_len_1),
        .i_cmd_data (cmd_data_1),
        .o_bit      (cmd_bit_1),
        .o_valid    (cmd_valid_1),
        .o_done     (cmd_done_1),
        .trig_start   (trig_start_1),
        .trig_end     (trig_end_1)
    );  
       
    mcst_encoder u_mcst_encoder_1
    (
        .o_enc_out  (cmd_out_1),
        .i_clk      (clk1x),
        .i_clk2x    (cmd_clk2x),
        .i_data_in  (cmd_bit_1),
        .i_enable   (cmd_valid_1)
    );       
    
    sequence_ctr u_seq_ctr_2
    (
       .ctr_en           (beamscan_en),
       .clk              (clk1x),
       .i_seq_end_addr   (seq_end_addr_2),
       .i_time_gap       (time_gap_2),
       .o_seq_addr         (seq_addr_2),
       .o_manchester_wren  (trig_scan_2)
    );

    cmd_serializer u_cmd_serializer_2
    (
        .i_clock    (clk1x),
        .i_reset    (reset),
        .i_trigger  (trig_2),
        .i_cmd_len  (cmd_len_2),
        .i_cmd_data (cmd_data_2),
        .o_bit      (cmd_bit_2),
        .o_valid    (cmd_valid_2),
        .o_done     (cmd_done_2),
        .trig_start (),
        .trig_end   ()
    );  
       
    mcst_encoder u_mcst_encoder_2
    (
        .o_enc_out   (cmd_out_2),
        .i_clk      (clk1x),
        .i_clk2x     (cmd_clk2x),
        .i_data_in  (cmd_bit_2),
        .i_enable   (cmd_valid_2)
    );        
    
    sequence_ctr u_seq_ctr_3
    (
       .ctr_en           (beamscan_en),
       .clk              (clk1x),
       .i_seq_end_addr   (seq_end_addr_3),
       .i_time_gap       (time_gap_3),
       .o_seq_addr         (seq_addr_3),
       .o_manchester_wren  (trig_scan_3)
    );

    cmd_serializer u_cmd_serializer_3
    (
        .i_clock    (clk1x),
        .i_reset    (reset),
        .i_trigger  (trig_3),
        .i_cmd_len  (cmd_len_3),
        .i_cmd_data (cmd_data_3),
        .o_bit      (cmd_bit_3),
        .o_valid    (cmd_valid_3),
        .o_done     (cmd_done_3),
        .trig_start   (trig_start_3),
        .trig_end     (trig_end_3)
    );  
       
    mcst_encoder u_mcst_encoder_3
    (
        .o_enc_out  (cmd_out_3),
        .i_clk      (clk1x),
        .i_clk2x    (cmd_clk2x),
        .i_data_in  (cmd_bit_3),
        .i_enable   (cmd_valid_3)
    );       
    
    sequence_ctr u_seq_ctr_4
    (
       .ctr_en           (beamscan_en),
       .clk              (clk1x),
       .i_seq_end_addr   (seq_end_addr_4),
       .i_time_gap       (time_gap_4),
       .o_seq_addr         (seq_addr_4),
       .o_manchester_wren  (trig_scan_4)
    );

    cmd_serializer u_cmd_serializer_4
    (
        .i_clock    (clk1x),
        .i_reset    (reset),
        .i_trigger  (trig_4),
        .i_cmd_len  (cmd_len_4),
        .i_cmd_data (cmd_data_4),
        .o_bit      (cmd_bit_4),
        .o_valid    (cmd_valid_4),
        .o_done     (cmd_done_4),
        .trig_start (),
        .trig_end   ()
    );  
       
    mcst_encoder u_mcst_encoder_4
    (
        .o_enc_out   (cmd_out_4),
        .i_clk      (clk1x),
        .i_clk2x     (cmd_clk2x),
        .i_data_in  (cmd_bit_4),
        .i_enable   (cmd_valid_4)
    );        
    
    // User logic ends

	endmodule
