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

module GreyDecode #(
    WIDTH = 2
) (
    input   wire logic[WIDTH-1:0]   enc_i,
    output  wire logic[WIDTH-1:0]   raw_o
);

logic [WIDTH-1:0] raw;
assign raw_o = raw;

if(WIDTH == 2) begin
    always_comb begin
        case(enc_i)
        'b00: raw = 'b00;
        'b01: raw = 'b01;
        'b11: raw = 'b10;
        'b10: raw = 'b11;
        endcase
    end
end else if(WIDTH == 3) begin
    always_comb begin
        case(enc_i)
        'b000: raw = 'b000;
        'b001: raw = 'b001;
        'b011: raw = 'b010;
        'b010: raw = 'b011;
        'b110: raw = 'b100;
        'b111: raw = 'b101;
        'b101: raw = 'b110;
        'b100: raw = 'b111;
        endcase
    end
end else if(WIDTH == 4) begin
    always_comb begin
        case(enc_i)
        'b0000: raw = 'b0000;
        'b0001: raw = 'b0001;
        'b0011: raw = 'b0010;
        'b0010: raw = 'b0011;
        'b0110: raw = 'b0100;
        'b0111: raw = 'b0101;
        'b0101: raw = 'b0110;
        'b0100: raw = 'b0111;
        'b1100: raw = 'b1000;
        'b1101: raw = 'b1001;
        'b1111: raw = 'b1010;
        'b1110: raw = 'b1011;
        'b1010: raw = 'b1100;
        'b1011: raw = 'b1101;
        'b1001: raw = 'b1110;
        'b1000: raw = 'b1111;
        endcase
    end
end else begin
    PanicModule panic();
end

endmodule