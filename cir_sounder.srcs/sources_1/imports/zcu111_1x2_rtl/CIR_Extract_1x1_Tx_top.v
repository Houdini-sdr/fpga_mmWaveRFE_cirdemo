module CIR_Extract_1x1_Tx_top #(
    parameter DATA_WIDTH = 16
) (
    input  en,
    input  rst_n,
    input  clk,
    output BD_real,
    output PD_real,
    output ctrl_sync,
    output [8*DATA_WIDTH-1:0] I_tdata,
    output [8*DATA_WIDTH-1:0] Q_tdata,
    output I_tvalid,
    output Q_tvalid,
    input  I_tready,
    input  Q_tready,
    // AXI Settings
    input [6:0] sector_id,      // max 128 sector
    input [7:0] radio_id,
    input [15:0] REAL_PD_SHIFT,
    input  [DATA_WIDTH-1:0] AMPLITUDE, // amplitude of DAC output
    input  [31:0] DELAY, // CC delay after transmitting one header
    input  [15:0] HEADER_PER_FRAME  // for each enable, 
);
    wire rst;
    assign rst = !rst_n;
    
    reg [15:0] Tx_count;    // Kai 05/28/2024
    wire Tx_done;            // Kai 05/28/2024
    assign Tx_done = (Tx_count == HEADER_PER_FRAME);
    
    reg ctrl_sync;

    reg [31:0] cnt;
    reg [127:0] Ga = 128'b11000000010110011100111101010110001111111010011011001111010101101100000001011001110011110101011011000000010110010011000010101001;
    reg [127:0] Gb = 128'b00111111101001100011000010101001110000000101100100110000101010011100000001011001110011110101011011000000010110010011000010101001;
    
    reg [31:0] Ga32 = 32'b11101101111000101110110100011101;
    reg [31:0] Gb32 = 32'b11101101111000100001001011100010;
    
    localparam payload_bits = 16;
    localparam payload_len = payload_bits * 32;
    wire [payload_len-1:0] chips_out;
    wire [7:0] sector_id_ex;
    wire crc;
      
    assign crc = sector_id[6]^sector_id[5]^sector_id[4]^sector_id[3]^sector_id[2]^sector_id[1]^sector_id[0];
    assign sector_id_ex = {sector_id, crc}; 
    
    
    genvar i;
    generate
    for (i = 0; i < 8; i = i + 1) begin : gen_spread
        assign chips_out[512-1-32*i -: 32] = radio_id[7-i] ? Ga32 : Gb32; //~Ga32
        assign chips_out[256-1-32*i -: 32] = sector_id_ex[7-i] ? Ga32 : Gb32; //~Ga32
//        assign chips_out[512-1-32*i -: 32] = radio_id[i] ? Ga32 : ~Ga32;
//        assign chips_out[256-1-32*i -: 32] = sector_id_ex[i] ? Ga32 : ~Ga32;
    end
    endgenerate    
    
    wire [0:(17+9)*128-1+ payload_len*2] G = {     // Kai 07/05/2024
        Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, Ga, -Ga, // STF
        -Gb, -Ga, Gb, -Ga, -Gb, Ga, -Gb, -Ga, -Gb, // CES
        chips_out, chips_out      //  Payload  Kai 04/23/2025
    };

    wire [DATA_WIDTH-1:0] Ir[0:7], Qr[0:7];
    reg  [7:0] I;

    wire i_ready = I_tready & Q_tready;
    reg  o_valid;
    
    assign I_tvalid = o_valid;
    assign Q_tvalid = o_valid;
    
    assign PD_real = cnt >= REAL_PD_SHIFT + 16'd16 & cnt <= REAL_PD_SHIFT + 16'd290;
 //   assign BD_real = cnt >= REAL_PD_SHIFT + 16'd256 & cnt <= REAL_PD_SHIFT + 16'd290;
    assign BD_real = cnt >= REAL_PD_SHIFT + 16'd264 & cnt <= REAL_PD_SHIFT + 16'd290;  
      
    assign I_tdata = { Ir[7], Ir[6], Ir[5], Ir[4], Ir[3], Ir[2], Ir[1], Ir[0] };
    assign Q_tdata = { Qr[7], Qr[6], Qr[5], Qr[4], Qr[3], Qr[2], Qr[1], Qr[0] };

    generate
        for (i = 0; i != 8; i = i + 1) begin: ROT
            Rotate rot (
                .en(o_valid),
                .ang(i[1:0]),
                .i(I[i]),
                .A(AMPLITUDE),
                .I_o(Ir[i]),
                .Q_o(Qr[i])
            );
        end
    endgenerate

    // TODO: modify this part to a state machine. Add states for payload extraction. 
    integer j;
    always@(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 0;
            o_valid <= 0;
            Tx_count <= 0;  // Kai 05/28/2024
            ctrl_sync <= 0; // kai 05/29/2024
        end
        else begin
            if (!en) begin  // Kai 05/28/2024
                Tx_count <= 0;
                ctrl_sync <= 0;
            end             
            if (en & i_ready & !Tx_done) begin
                ctrl_sync <= 1;  // Kai 05/29/2024
                if (cnt <= ((17+9)*128 + payload_len*2) / 8) begin // Kai 04/21/2025
                    o_valid <= 1;
                    for (j = 0; j != 8; j = j + 1) begin
                        I[j] <= G[8*cnt+j];
                    end
                    cnt <= cnt + 1;
                end
                else if (cnt <= ((17+9)*128 + payload_len*2) / 8 + DELAY) begin // Kai 04/21/2025
                    o_valid <= 0;
                    cnt <= cnt + 1;
                end
                else begin 
                    cnt <= 0;
                    o_valid <= 0;
                    Tx_count <= Tx_count + 1;
                end
            end
            else begin
                o_valid <= 0;
                ctrl_sync <= 0;
            end
        end
    end

endmodule
