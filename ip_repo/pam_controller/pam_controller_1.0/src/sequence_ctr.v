module sequence_ctr
    (
        input ctr_en,
        input clk,
        input [15:0] i_seq_end_addr,
        input [15:0] i_time_gap,
        output reg [15:0] o_seq_addr=16'd0,
        output reg o_manchester_wren=1'b0
    );

reg [15:0] gap_cnt = 16'd0;

reg ctr_en_d = 1'b0;
wire ctr_en_end, ctr_en_begin;
always@(posedge clk)
    ctr_en_d <= ctr_en;
assign ctr_en_end = ~ctr_en && ctr_en_d;
assign ctr_en_begin = ctr_en && ~ctr_en_d;

always@(posedge clk) begin
    // If we're only sending 1 PA command, this module just needs to 
    // send a trigger signal to the manchester encoder module when 
    // the txrx input goes high
    if (i_seq_end_addr == 16'd0)
        o_manchester_wren <= ctr_en_begin;
    else if (ctr_en && gap_cnt == 16'd0) begin
        o_manchester_wren <= 1'b1;
        gap_cnt <= 16'd1;
        // We advance to the 2nd address here, since data is latched and 
        // it takes 1 clock cycle to fetch new data from memory
        //o_seq_addr <= 16'd1;
    end
    else if (ctr_en && gap_cnt == i_time_gap) begin
        // Reached end of counter, increment o_seq_addr
        o_manchester_wren <= 1'b1;
        gap_cnt <= 16'd1;
        if (o_seq_addr == i_seq_end_addr)
            o_seq_addr <= 16'd0;
        else
            o_seq_addr <= o_seq_addr + 1'b1;
    end
    else if (ctr_en) begin
        // Increment counter
        o_manchester_wren <= 1'b0;
        gap_cnt <= gap_cnt + 1'b1;
    end
    else if (ctr_en_end) begin
        o_manchester_wren <= 1'b0;
        gap_cnt <= 16'd0;
        o_seq_addr <= 16'd0;
    end
end
endmodule