`timescale 1ns / 1ps

module tb_Payload_extract;
  // -----------------------------------------------------------------------
  // Parameters
  // -----------------------------------------------------------------------
  parameter DATA_WIDTH   = 16;
  parameter PAYLOAD_LEN  = 16;  // shorten for testbench
  parameter BD_HEADER_DLY_CC  = 8;  // shorten for testbench
  
  // -----------------------------------------------------------------------
  // Signals
  // -----------------------------------------------------------------------
  reg                          clk;
  reg                          rst;
  reg                          start_collect;
  reg                          cir_tx_last;
  reg signed [DATA_WIDTH-1:0]  I1, I2, I3, I4, I5, I6, I7, I8;
  reg signed [DATA_WIDTH-1:0]  Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8;

  wire [DATA_WIDTH*8-1:0]      Payload_I_out;
  wire [DATA_WIDTH*8-1:0]      Payload_Q_out;
  wire                         o_valid;
  wire                         o_last;

  // -----------------------------------------------------------------------
  // Instantiate DUT
  // -----------------------------------------------------------------------
  Payload_extract #(
    .DATA_WIDTH  (DATA_WIDTH),
    .PAYLOAD_LEN (PAYLOAD_LEN),
    .BD_HEADER_DLY_CC (BD_HEADER_DLY_CC)
  ) uut (
    .clk           (clk),
    .rst           (rst),
    .start_collect (start_collect),
    .cir_tx_last   (cir_tx_last),
    .I1            (I1),
    .I2            (I2),
    .I3            (I3),
    .I4            (I4),
    .I5            (I5),
    .I6            (I6),
    .I7            (I7),
    .I8            (I8),
    .Q1            (Q1),
    .Q2            (Q2),
    .Q3            (Q3),
    .Q4            (Q4),
    .Q5            (Q5),
    .Q6            (Q6),
    .Q7            (Q7),
    .Q8            (Q8),
    .Payload_I_out (Payload_I_out),
    .Payload_Q_out (Payload_Q_out),
    .o_valid       (o_valid),
    .o_last        (o_last)
  );

  // -----------------------------------------------------------------------
  // Clock generation: 10 ns period
  // -----------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // -----------------------------------------------------------------------
  // Test sequence
  // -----------------------------------------------------------------------
  integer i;
  initial begin
    // -- Initialize
    rst           = 1;
    start_collect = 0;
    cir_tx_last   = 0;
    {I1,I2,I3,I4,I5,I6,I7,I8} = 0;
    {Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8} = 0;

    // -- Release reset
    #20;
    rst = 0;
    #10;

    // -- 1) Trigger collection
    start_collect = 1;
    #10;
    start_collect = 0;

    // -- 2) Feed PAYLOAD_LEN samples
    for (i = 0; i < PAYLOAD_LEN + BD_HEADER_DLY_CC; i = i + 1) begin
      // simple ramp on I, negative ramp on Q
      I1 =  i; I2 =  i+1; I3 =  i+2; I4 =  i+3;
      I5 =  i+4; I6 =  i+5; I7 =  i+6; I8 =  i+7;
      Q1 = -i; Q2 = -i-1; Q3 = -i-2; Q4 = -i-3;
      Q5 = -i-4; Q6 = -i-5; Q7 = -i-6; Q8 = -i-7;
      #10;
      
      if (i == 10) begin
        cir_tx_last = 1;
      end 
      if (i == 11) begin
        cir_tx_last = 0;
      end 
    end

    // -- 3) Wait and trigger transmit
//    #100;
//    cir_tx_last = 1;
//    #10;
//    cir_tx_last = 0;

    // -- 4) Let all data come out, then finish
    #(PAYLOAD_LEN*10 + 20);
    $display("*** Testbench completed ***");
    $finish;
  end

  // -----------------------------------------------------------------------
  // Monitor outputs
  // -----------------------------------------------------------------------
  always @(posedge clk) begin
    if (o_valid) begin
      $display("Time=%0t | VALID | I_out=0x%h | Q_out=0x%h", 
               $time, Payload_I_out, Payload_Q_out);
    end
    if (o_last) begin
      $display("Time=%0t | LAST asserted, end of transmission", $time);
    end
  end

endmodule
