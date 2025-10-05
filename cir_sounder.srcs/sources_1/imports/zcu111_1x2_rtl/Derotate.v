module Derotate #(
    parameter DATA_WIDTH = 1,
    parameter DISABLE = 0
) (
    input         [1:0]            ang, // 2'b00: 0, 2'b01: pi/2, 2'b10: pi, 2'b11: -pi/2
    input  signed [DATA_WIDTH-1:0] I_i,
    input  signed [DATA_WIDTH-1:0] Q_i,
    output signed [DATA_WIDTH-1:0] I_o,
    output signed [DATA_WIDTH-1:0] Q_o
);

    generate

        if (DISABLE) begin
            assign I_o = I_i;
            assign Q_o = Q_i;
        end
        else begin
            assign I_o = Derotate_I(I_i, Q_i, ang);
            assign Q_o = Derotate_Q(I_i, Q_i, ang);
        end

        function [DATA_WIDTH-1:0] Derotate_I(
            input [DATA_WIDTH-1:0] I_i,
            input [DATA_WIDTH-1:0] Q_i,
            input [1:0]            ang
        );
            case (ang)
                2'b00  : Derotate_I = +I_i;
                2'b01  : Derotate_I = +Q_i;
                2'b10  : Derotate_I = -I_i;
                2'b11  : Derotate_I = -Q_i;
                default: Derotate_I = +I_i;
            endcase
        endfunction

        function [DATA_WIDTH-1:0] Derotate_Q(
            input [DATA_WIDTH-1:0] I_i,
            input [DATA_WIDTH-1:0] Q_i,
            input [1:0]            ang
        );
            case (ang)
                2'b00  : Derotate_Q = +Q_i;
                2'b01  : Derotate_Q = -I_i;
                2'b10  : Derotate_Q = -Q_i;
                2'b11  : Derotate_Q = +I_i;
                default: Derotate_Q = +Q_i;
            endcase
        endfunction

    endgenerate

endmodule
