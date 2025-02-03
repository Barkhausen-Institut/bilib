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

module _8b10bEncode (
    input   wire _8b10b::symbol     raw_i,      // KHGFEDCBA
    input   wire logic              RD_i,       // running disparity 0:-1 1:1
    output  wire _8b10b::symbol10   encoded_o,  // abdceifghj
    output  wire logic              RDNext_o
);

//char9 disassamble
logic [2:0] three;  //three upper bits (HGF)
logic [4:0] five;   //five lower bits  (EDCBA)
logic       isK;    //is it a K group
assign {isK, three, five} = raw_i;

//5b/6b
logic [6:0] LUT5b6b; // Dabcdei
always_comb begin : enc5b6b
    casex({RD_i, five})
        6'b000000: LUT5b6b = 7'b1100111;
        6'b100000: LUT5b6b = 7'b1011000;
        6'b000001: LUT5b6b = 7'b1011101;
        6'b100001: LUT5b6b = 7'b1100010;
        6'b000010: LUT5b6b = 7'b1101101;
        6'b100010: LUT5b6b = 7'b1010010;
        6'bx00011: LUT5b6b = 7'b0110001;
        6'b000100: LUT5b6b = 7'b1110101;
        6'b100100: LUT5b6b = 7'b1001010;
        6'bx00101: LUT5b6b = 7'b0101001;
        6'bx00110: LUT5b6b = 7'b0011001;
        6'b000111: LUT5b6b = 7'b0111000;
        6'b100111: LUT5b6b = 7'b0000111;
        6'b001000: LUT5b6b = 7'b1111001;
        6'b101000: LUT5b6b = 7'b1000110;
        6'bx01001: LUT5b6b = 7'b0100101;
        6'bx01010: LUT5b6b = 7'b0010101;
        6'bx01011: LUT5b6b = 7'b0110100;
        6'bx01100: LUT5b6b = 7'b0001101;
        6'bx01101: LUT5b6b = 7'b0101100;
        6'bx01110: LUT5b6b = 7'b0011100;
        6'b001111: LUT5b6b = 7'b1010111;
        6'b101111: LUT5b6b = 7'b1101000;
        6'b010000: LUT5b6b = 7'b1011011;
        6'b110000: LUT5b6b = 7'b1100100;
        6'bx10001: LUT5b6b = 7'b0100011;
        6'bx10010: LUT5b6b = 7'b0010011;
        6'bx10011: LUT5b6b = 7'b0110010;
        6'bx10100: LUT5b6b = 7'b0001011;
        6'bx10101: LUT5b6b = 7'b0101010;
        6'bx10110: LUT5b6b = 7'b0011010;
        6'b010111: LUT5b6b = 7'b1111010;
        6'b110111: LUT5b6b = 7'b1000101;
        6'b011000: LUT5b6b = 7'b1110011;
        6'b111000: LUT5b6b = 7'b1001100;
        6'bx11001: LUT5b6b = 7'b0100110;
        6'bx11010: LUT5b6b = 7'b0010110;
        6'b011011: LUT5b6b = 7'b1110110;
        6'b111011: LUT5b6b = 7'b1001001;
        6'b011100: LUT5b6b = isK ? 7'b1001111 : 7'b0001110;
        6'b111100: LUT5b6b = isK ? 7'b1110000 : 7'b0001110;
        6'b011101: LUT5b6b = 7'b1101110;
        6'b111101: LUT5b6b = 7'b1010001;
        6'b011110: LUT5b6b = 7'b1011110;
        6'b111110: LUT5b6b = 7'b1100001;
        6'b011111: LUT5b6b = 7'b1101011;
        6'b111111: LUT5b6b = 7'b1010100;
        //default: LUT5b6b = RD_i ? 7'b1111100 : 7'b1000011; //unused symbol - MH: DC says it is not reacable
    endcase
end

logic [5:0] six;        //5b6b encoded (abcdei)
logic       sixChgDisp; //disparity change after 5b6b
logic       RD_six;     //disparity after 5b6b

assign six = LUT5b6b[5:0];
assign sixChgDisp = LUT5b6b[6];
assign RD_six = RD_i ^ sixChgDisp;

// 'b111 special case detection
logic alternate7; //use alternate code on 'b111 input
always_comb begin : alt7
    case(five)
    5'd17,
    5'd18,
    5'd20: alternate7 = RD_six == 1'b0 ? 1'b1 : 1'b0;
    5'd11,
    5'd13,
    5'd14: alternate7 = RD_six == 1'b1 ? 1'b1 : 1'b0;
    default: alternate7 = 1'b0;
    endcase    
end

//3b/4b
logic [4:0] LUT3b4b; //Dfghj
always_comb begin : enc3b4b
    casex ({isK, RD_six, three})
    5'bx0000: LUT3b4b = 5'b11011;//0
    5'bx1000: LUT3b4b = 5'b10100;
    5'b0x001: LUT3b4b = 5'b01001;//1
    5'b10001: LUT3b4b = 5'b00110;
    5'b11001: LUT3b4b = 5'b01001;
    5'b0x010: LUT3b4b = 5'b00101;//2
    5'b10010: LUT3b4b = 5'b01010;
    5'b11010: LUT3b4b = 5'b00101;
    5'bx0011: LUT3b4b = 5'b01100;//3
    5'bx1011: LUT3b4b = 5'b00011;
    5'bx0100: LUT3b4b = 5'b11101;//4
    5'bx1100: LUT3b4b = 5'b10010;
    5'b0x101: LUT3b4b = 5'b01010;//5
    5'b10101: LUT3b4b = 5'b00101;
    5'b11101: LUT3b4b = 5'b01010;
    5'b0x110: LUT3b4b = 5'b00110;//6
    5'b10110: LUT3b4b = 5'b01001;
    5'b11110: LUT3b4b = 5'b00110;
    5'b00111: LUT3b4b = alternate7 ? 5'b10111 : 5'b11110;//7
    5'b01111: LUT3b4b = alternate7 ? 5'b11000 : 5'b10001;
    5'b10111: LUT3b4b = 5'b10111;
    5'b11111: LUT3b4b = 5'b11000;
    //default: LUT3b4b = 5'b00000; //invalid - MH: DC says it is unreachable
    endcase
end

logic [3:0] four;           //3b4b encoded (fghj)
logic       fourChgDisp;    //disparity changed after 3b4b
logic       RD_four;        //disparity after 3b4b

assign four = LUT3b4b[3:0];
assign fourChgDisp = LUT3b4b[4];
assign RD_four = RD_six ^ fourChgDisp;


//output
assign encoded_o = {six, four}; // abdceifghj
assign RDNext_o = RD_four;

endmodule