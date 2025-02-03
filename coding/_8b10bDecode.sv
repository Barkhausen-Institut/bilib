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

module _8b10bDecode (
    input   wire _8b10b::symbol10   encoded_i,  // abdceifghj
    output  wire _8b10b::symbol     raw_o       // KHGFEDCBA
);
    
logic [3:0] four; // fghj
logic [5:0] six;  // abcdei
assign four = encoded_i[3:0];
assign six =  encoded_i[9:4];

logic [4:0] LUT6b5b; //EDCBA
always_comb begin : dec6b5b
    case(six)
        6'b100111,
        6'b011000: LUT6b5b = 5'b00000;
        6'b011101,
        6'b100010: LUT6b5b = 5'b00001;
        6'b101101,
        6'b010010: LUT6b5b = 5'b00010;
        6'b110001: LUT6b5b = 5'b00011;
        6'b110101,
        6'b001010: LUT6b5b = 5'b00100;
        6'b101001: LUT6b5b = 5'b00101;
        6'b011001: LUT6b5b = 5'b00110;
        6'b111000,
        6'b000111: LUT6b5b = 5'b00111;
        6'b111001,
        6'b000110: LUT6b5b = 5'b01000;
        6'b100101: LUT6b5b = 5'b01001;
        6'b010101: LUT6b5b = 5'b01010;
        6'b110100: LUT6b5b = 5'b01011;
        6'b001101: LUT6b5b = 5'b01100;
        6'b101100: LUT6b5b = 5'b01101;
        6'b011100: LUT6b5b = 5'b01110;
        6'b010111,
        6'b101000: LUT6b5b = 5'b01111;
        6'b011011,
        6'b100100: LUT6b5b = 5'b10000;
        6'b100011: LUT6b5b = 5'b10001;
        6'b010011: LUT6b5b = 5'b10010;
        6'b110010: LUT6b5b = 5'b10011;
        6'b001011: LUT6b5b = 5'b10100;
        6'b101010: LUT6b5b = 5'b10101;
        6'b011010: LUT6b5b = 5'b10110;
        6'b111010,
        6'b000101: LUT6b5b = 5'b10111; //K
        6'b110011,
        6'b001100: LUT6b5b = 5'b11000;
        6'b100110: LUT6b5b = 5'b11001;
        6'b010110: LUT6b5b = 5'b11010;
        6'b110110,
        6'b001001: LUT6b5b = 5'b11011; //K
        6'b001110: LUT6b5b = 5'b11100;
        6'b101110,
        6'b010001: LUT6b5b = 5'b11101; //K
        6'b011110,
        6'b100001: LUT6b5b = 5'b11110; //K
        6'b101011,
        6'b010100: LUT6b5b = 5'b11111;
        6'b001111,
        6'b110000: LUT6b5b = 5'b11100; //K!
        default:   LUT6b5b = 5'b00000; //K - should be invalid
    endcase
end

logic [4:0] five;
assign      five = LUT6b5b[4:0];

logic       isK28p;
logic       isK28n;
logic       isK28;
assign      isK28p = six == 'b110000 ? 1'b1 : 1'b0;
assign      isK28n = six == 'b001111 ? 1'b1 : 1'b0;
assign      isK28 = isK28p | isK28n;

logic       sixHintK;
always_comb begin : checkHintK
    case (six)
        6'b111010,
        6'b000101,
        6'b110110,
        6'b001001,
        6'b101110,
        6'b010001,
        6'b011110,
        6'b100001:  sixHintK = 1'b1;
        default:    sixHintK = 1'b0;
    endcase
end

logic sixHintError;
assign sixHintError =
    LUT6b5b == 5'b0     //error or real zero
 && six != 6'b100111    //real ecoding for zero
 && six != 6'b011000
  ? 1'b1 : 1'b0;

logic [3:0] LUT4b3b; // KHGF
always_comb begin : dec4b3b
    case (four)
        4'b1011,
        4'b0100: LUT4b3b = 3'b000;
        4'b0110: LUT4b3b = isK28p ? 3'b001 : 3'b110;
        4'b1001: LUT4b3b = isK28p ? 3'b110 : 3'b001;
        4'b1010: LUT4b3b = isK28p ? 3'b010 : 3'b101;
        4'b0101: LUT4b3b = isK28p ? 3'b101 : 3'b010;
        4'b1100,
        4'b0011: LUT4b3b = 3'b011;
        4'b1101,
        4'b0010: LUT4b3b = 3'b100;
        4'b1110,
        4'b0001,
        4'b0111,
        4'b1000: LUT4b3b = 3'b111;
        default: LUT4b3b = 3'b000;
    endcase
end

logic fourHintError;
assign fourHintError = 
    LUT4b3b == 3'b0 // error or zero
 && four != 4'b1011 // real encoding for 0
 && four != 4'b0100
  ? 1'b1 : 1'b0;

logic [2:0] three;
logic       fourHintK;
assign three = LUT4b3b;
assign fourHintK = 
    four == 4'b0111 || four == 4'b1000 ? 1'b1 : 1'b0;

logic isK;
assign isK =
    isK28 == 1'b1 ? 1'b1 :
    sixHintK == 1'b1 && fourHintK == 1'b1 ? 1'b1 :
    1'b0;

logic isError;
assign isError =
    sixHintError == 1'b1
 || fourHintError == 1'b1
  ? 1'b1 : 1'b0;

assign raw_o = isError == 1'b1 ? _8b10b::K(0,0) : {isK, three, five};

endmodule