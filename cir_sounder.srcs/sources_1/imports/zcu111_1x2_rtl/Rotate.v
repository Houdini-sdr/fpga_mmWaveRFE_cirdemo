module Rotate #(
    parameter DATA_WIDTH = 16 // <-- DO NOT CHANGE THIS
) (
    input                          en,
    input         [1:0]            ang, // 2'b00: 0, 2'b01: pi/2, 2'b10: pi, 2'b11: -pi/2
    input                          i,
    input  signed [DATA_WIDTH-1:0] A, // amplitude
    output signed [DATA_WIDTH-1:0] I_o,
    output signed [DATA_WIDTH-1:0] Q_o
);

    generate

        assign I_o = Rotate_I(en, i, ang);
        assign Q_o = Rotate_Q(en, i, ang);

        function [DATA_WIDTH-1:0] Rotate_I(
            input en,
            input i,
            input [1:0] ang
        );
            if (en)
                case (ang + {i, 1'b0})
                    2'b00  : Rotate_I = A;
                    2'b01  : Rotate_I = 16'b0;
                    2'b10  : Rotate_I = -A;
                    2'b11  : Rotate_I = 16'b0;
                endcase
            else Rotate_I = 16'b0;
        endfunction

        function [DATA_WIDTH-1:0] Rotate_Q(
            input en,
            input i,
            input [1:0] ang
        );
            if (en)
                case (ang + {i, 1'b0})
                    2'b00  : Rotate_Q = 16'b0;
                    2'b01  : Rotate_Q = A;
                    2'b10  : Rotate_Q = 16'b0;
                    2'b11  : Rotate_Q = -A;
                endcase
            else Rotate_Q = 16'b0;
        endfunction

    endgenerate

endmodule
