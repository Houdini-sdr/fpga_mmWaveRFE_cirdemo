`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/02/2024 05:35:49 PM
// Design Name: 
// Module Name: cmd_serializer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module cmd_serializer(
    input i_clock,
    input i_trigger,
    input i_reset,
    input [7:0] i_cmd_len,
    input [0:94] i_cmd_data,
    output reg o_bit,
    output reg o_done,
    output reg o_valid,
    output reg trig_start,
    output reg trig_end
    );
    
    localparam  IDLE = 2'b00,
                ACTIVE = 2'b01,
                DONE = 2'b10;
    
    reg [1:0]   state = IDLE;  
    reg [0:94]  r_cmd = 0;
    reg [7:0]   r_len = 0;
    reg [7:0]   cnt = 0;  

    reg r_trig = 1'b0;
    always @ (posedge i_clock) begin
        r_trig <= i_trigger;
//        trig_end <= ~i_trigger && r_trig;
        trig_start <= i_trigger && ~r_trig;
    end
//    assign trig_end = ~i_trigger && r_trig;
//    assign trig_start = i_trigger && ~r_trig;

    initial begin
        o_bit <= 1'b0;
        o_done <= 1'b0;
        o_valid <= 0;
    end
            
    always @(posedge i_clock) begin 
        if (i_reset == 1'b1) begin
            state <= IDLE;
            r_cmd <= 0;
            r_len <= 0;
            cnt <= 0;
            o_valid <= 0;
            o_bit <= 1'b0;
        end else begin  
            case (state)
                IDLE: begin
                    if (trig_start == 1'b1) begin
                        state <= ACTIVE;
                        r_cmd <= i_cmd_data;
                        r_len <= i_cmd_len;  
                        o_done <= 1'b0;
                        o_valid <= 1'b0;
                        cnt <= 0;
                    end else begin
                        state <= IDLE;
                        r_cmd <= i_cmd_data;
                        r_len <= i_cmd_len;
                        o_valid <= 1'b0;
                    end
                end
                ACTIVE: begin
                    if (cnt == r_len) begin
                        state <= IDLE;
                        cnt <= 0;
                        r_cmd <= 0;
                        r_len <= 0;
                        o_valid <= 1'b0;
                        o_done <= 1'b1;
                        o_bit <= 1'b0;
                    end else begin
                        state <= ACTIVE;
                        cnt <= cnt + 1;
                        o_bit <= r_cmd[cnt];
                        o_valid <= 1'b1;
                    end
                end
//                DONE: begin
//                    if (trig_end == 1'b1) begin
//                        o_done <= 1'b0;
//                        state <= IDLE;
//                    end else begin
//                        o_done <= 1'b1;
//                        state <= DONE;    
//                    end
//                end
                default: begin
                    o_done <= 1'b0;
                    state <= IDLE;
                end 
            endcase
        end
    end
endmodule
