`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kai Zheng
// 
// Create Date: 05/08/2025 09:51:53 AM
// Design Name: 
// Module Name: Payload_extract
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


module Payload_extract #(
    parameter DATA_WIDTH = 16,
    parameter PAYLOAD_LEN = 64+32,
    parameter BD_HEADER_DLY_CC = 144-16 // add some tolerance
) (
    input clk, 
    input rst,
    input start_collect,
    input cir_tx_last,
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
    output reg [DATA_WIDTH*8-1:0] Payload_I_out,
    output reg [DATA_WIDTH*8-1:0] Payload_Q_out,
    output reg o_valid,
    output reg o_last         // delay the "last" signal from the CIR_EST block for one clock cycle. 
    );
    
    wire [DATA_WIDTH*8-1:0] Payload_I_in;
    wire [DATA_WIDTH*8-1:0] Payload_Q_in;
    
    reg [DATA_WIDTH*8-1:0] Payload_buffer_I [0:PAYLOAD_LEN-1];
    reg [DATA_WIDTH*8-1:0] Payload_buffer_Q [0:PAYLOAD_LEN-1];
    
    assign Payload_I_in = {I8, I7, I6, I5, I4, I3, I2, I1};
    assign Payload_Q_in = {Q8, Q7, Q6, Q5, Q4, Q3, Q2, Q1};

    localparam [2:0] IDLE = 3'b000;         // 
    localparam [2:0] BD = 3'b001;           // STF end, Packet Boundary detect = 1
    localparam [2:0] COLLECT = 3'b010;      // CE end, Payload start 
    localparam [2:0] WAIT = 3'b011;         // CIR transmitting, wait...
    localparam [2:0] TX = 3'b100;           // CIR transmit done, payload transmit
    localparam [2:0] TX_LAST = 3'b101;      // payload tx done. 
    
    //localparam [7:0] BD_HEADER_DLY_CC = 8'd136; // ideal = 144 
    
    reg [2:0] curr_state = IDLE;
    reg [2:0] next_state = IDLE;
    reg [7:0] cnt_payload = 8'b0;         // payload counter
    reg [7:0] cnt_delay = 8'b0;        // boundary detect --> payload delay counter

    reg cir_tx_done = 1'b0;
    
    integer i;

    // change state
    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            curr_state <= IDLE;
        end else begin 
            curr_state <= next_state;
        end
    end 
    
    // Describe the state transition logic 
    always @(*) begin 
        next_state = IDLE;
        case (curr_state) 
            IDLE: begin
                if (start_collect == 1'b1) begin
                    next_state = BD;         
                end else begin
                    next_state = IDLE;
                end
            end
            
            BD: begin
                if (cnt_delay == BD_HEADER_DLY_CC - 1) begin
                    next_state = COLLECT;         
                end else begin
                    next_state = BD;
                end
            end
            
            COLLECT: begin
                if (cnt_payload == PAYLOAD_LEN) begin
                    if (cir_tx_done == 1'b1) begin
                        next_state = TX;
                    end else begin
                        next_state = WAIT;
                    end
                end else begin
                    next_state = COLLECT;
                end
            end
            
            WAIT: begin
                if (cir_tx_done == 1'b1) begin
                    next_state = TX;
                end else begin
                    next_state = WAIT;
                end

            end
            
            TX: begin
                if (cnt_payload == PAYLOAD_LEN - 1) begin
                    next_state = TX_LAST;
                end else begin
                    next_state = TX;
                end
            end
            
            TX_LAST: begin
                next_state = IDLE;
            end      
                  
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            Payload_I_out <= 0;
            Payload_Q_out <= 0;
            o_valid <= 0;
            o_last <= 0;

            cir_tx_done <= 1'b0;            
            cnt_payload <= 0;
            cnt_delay <= 0;
            for (i = 0; i < PAYLOAD_LEN; i = i + 1) begin
                Payload_buffer_I[i] <= 0;
                Payload_buffer_Q[i] <= 0;
            end
            
        end else begin 
            case (next_state) 
                IDLE: begin
                    Payload_I_out <= 0;
                    Payload_Q_out <= 0;
                    o_valid <= 0;
                    o_last <= 0;
                    cir_tx_done <= 1'b0; 
                    
                    cnt_payload <= 0;
                    cnt_delay <= 0;
                    for (i = 0; i < PAYLOAD_LEN; i = i + 1) begin
                        Payload_buffer_I[i] <= 0;
                        Payload_buffer_Q[i] <= 0;
                    end
                end 
                
                BD: begin
                    Payload_I_out <= 0;
                    Payload_Q_out <= 0;
                    o_valid <= 0;
                    o_last <= 0;
                    
                    cnt_delay <= cnt_delay + 1;
                    cir_tx_done <= 1'b0;
                end 
                
                COLLECT: begin
                    Payload_I_out <= 0;
                    Payload_Q_out <= 0;
                    o_valid <= 0;
                    o_last <= 0;
                    
                    Payload_buffer_I[cnt_payload] <= Payload_I_in;
                    Payload_buffer_Q[cnt_payload] <= Payload_Q_in;
                    cnt_payload <= cnt_payload + 1;
                    
                    // cir_tx_done keeps the cir_tx_last = 1 status  
                    if (cir_tx_last == 1'b1) begin 
                        cir_tx_done <= 1'b1;  
                    end
                end
                
                WAIT: begin
                    Payload_I_out <= 0;
                    Payload_Q_out <= 0;
                    o_valid <= 0;
                    o_last <= 0;
                    
                    cnt_payload <= 0;
                    if (cir_tx_last == 1'b1) begin 
                        cir_tx_done <= 1'b1;   
                    end
                end
                
                TX: begin
                    o_valid <= 1'b1;
                    o_last <= 0;
                    if (curr_state != TX) begin
                        Payload_I_out <= Payload_buffer_I[0];
                        Payload_Q_out <= Payload_buffer_Q[0];
                        cnt_payload <= 1;
                    end else begin
                        Payload_I_out <= Payload_buffer_I[cnt_payload];
                        Payload_Q_out <= Payload_buffer_Q[cnt_payload];
                        cnt_payload <= cnt_payload + 1;
                    end
                    cir_tx_done <= 1'b0;
                end
                
                TX_LAST: begin
                    o_valid <= 1'b1;
                    o_last <= 1'b1;
                    Payload_I_out <= Payload_buffer_I[cnt_payload];
                    Payload_Q_out <= Payload_buffer_Q[cnt_payload];
                    
                    cnt_payload <= 0;
                end
                
                default:  begin
                    Payload_I_out <= 0;
                    Payload_Q_out <= 0;
                    o_valid <= 0;
                    o_last <= 0;
                    
                    cnt_payload <= 0;
                    cnt_delay <= 0;
                end
            endcase
        end
    end 
    
endmodule
