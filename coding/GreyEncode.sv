////    ////////////    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
////    ////////////    
////                    This source describes Open Hardware and is licensed under the
////                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
////////////    ////    
////////////    ////    
////    ////    ////    
////    ////    ////    
////////////            Authors:
////////////            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

`default_nettype none

module GreyEncode #(
    WIDTH = 2
) (
    input   wire logic[WIDTH-1:0]   raw_i,
    output  wire logic[WIDTH-1:0]   enc_o
);

logic[WIDTH-1:0] enc;
assign enc_o = enc;

if(WIDTH == 2) begin
    always_comb begin
        case(raw_i)
        'b00: enc = 'b00;
        'b01: enc = 'b01;
        'b10: enc = 'b11;
        'b11: enc = 'b10;
        endcase
    end
end else if(WIDTH == 3) begin
    always_comb begin
        case(raw_i)
        'b000: enc = 'b000;
        'b001: enc = 'b001;
        'b010: enc = 'b011;
        'b011: enc = 'b010;
        'b100: enc = 'b110;
        'b101: enc = 'b111;
        'b110: enc = 'b101;
        'b111: enc = 'b100;
        endcase
    end
end else if(WIDTH == 4) begin
    always_comb begin
        case(raw_i)
        'b0000: enc = 'b0000;
        'b0001: enc = 'b0001;
        'b0010: enc = 'b0011;
        'b0011: enc = 'b0010;
        'b0100: enc = 'b0110;
        'b0101: enc = 'b0111;
        'b0110: enc = 'b0101;
        'b0111: enc = 'b0100;
        'b1000: enc = 'b1100;
        'b1001: enc = 'b1101;
        'b1010: enc = 'b1111;
        'b1011: enc = 'b1110;
        'b1100: enc = 'b1010;
        'b1101: enc = 'b1011;
        'b1110: enc = 'b1001;
        'b1111: enc = 'b1000;
        endcase
    end
end else begin
    PanicModule panic();
end

endmodule