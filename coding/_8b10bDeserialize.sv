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


module _8b10bDeserialize (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    output  wire _8b10b::pair10     parallel_o,
    output  wire logic              valid_o,
    input   wire logic[2:0]         serial_i,   //older -> newer
    input   wire logic[1:0]         valid_i,    //valid values: [0,3]
    input   wire logic              enReAlign_i
);

import _8b10b::*;

//input
logic [21:0]    shiftreg;
always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)           shiftreg <= 'b1010101010101010101010;
    else if(valid_i == 2'd1)    shiftreg <= {shiftreg[19:0], serial_i[2]};
    else if(valid_i == 2'd2)    shiftreg <= {shiftreg[18:0], serial_i[2:1]};
    else if(valid_i == 2'd3)    shiftreg <= {shiftreg[17:0], serial_i};
    else                        shiftreg <= shiftreg;
end

//komma detection
// detect K(28,5) -- K(28,7) not allowed
// detect only in first symbol of pair
logic kommaHigh2;       //komma with shiftreg[17] as MSB
logic kommaHigh;        //komma with shiftreg[18] as MSB
logic kommaLow;         //komma with shiftreg[19] as MSB

assign kommaLow =
    shiftreg[7:0] == 8'b00111110
 || shiftreg[7:0] == 8'b11000001
  ? 1'b1 : 1'b0;

//if two bits come in, komma may be found at bit 1 upwards
assign kommaHigh =
    shiftreg[8:1] == 8'b00111110
 || shiftreg[8:1] == 8'b11000001
  ? 1'b1 : 1'b0;

//if two bits come in, komma may be found at bit 1 upwards
assign kommaHigh2 =
    shiftreg[9:2] == 8'b00111110
 || shiftreg[9:2] == 8'b11000001
  ? 1'b1 : 1'b0;

logic aligned;  //komma alignment
logic kommaSet; //decision to reset counter
assign kommaSet =
    (kommaLow || kommaHigh || kommaHigh2)
 && (~aligned || enReAlign_i)
  ? 1'b1 : 1'b0;

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)           aligned <= 1'b0;
    else if(kommaSet == 1'b1)   aligned <= 1'b1;
    else                        aligned <= aligned;
end

logic[4:0] counterInc;
assign counterInc = valid_i;
//    valid_i == 2'b01 ? 4'd1:
//    valid_i == 2'b11 ? 4'd2:
//                       4'd0;

logic[4:0] counter;
logic[4:0] counterSet;
always_comb begin
    if(kommaSet == 1'b1) begin
        if(kommaHigh)           counterSet = 4'd9;
        else if(kommaHigh2)     counterSet = 4'd10;
        else                    counterSet = 4'd8;
    end else if(counter == 20)  counterSet = 4'd0;
    else if(counter == 21)      counterSet = 4'd1;
    else if(counter == 22)      counterSet = 4'd2;
    else                        counterSet = counter;
end

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)   counter <= 0;
    else                counter <= counterSet + counterInc;            
end

//when more bits come in at once the word may be finished with different counter values
logic validHigh2;
logic validHigh;
logic validLow;
logic valid;
assign validHigh2 = counter == 22 && aligned == 1'b1;
assign validHigh = counter == 21 && aligned == 1'b1;
assign validLow = counter == 20 && aligned == 1'b1;
assign valid = validHigh | validLow | validHigh2;

logic [19:0] validData;
assign validData = 
    validHigh2 == 1'b1  ? shiftreg[21:2]:
    validHigh == 1'b1   ? shiftreg[20:1]:
    validLow == 1'b1    ? shiftreg[19:0]:
                          '0;

logic[19:0] buffer;
always_ff @( posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)           buffer <= '0;
    else if(valid == 1'b1)      buffer <= validData;
    else                        buffer <= buffer;
end

assign valid_o = valid;
assign parallel_o = valid == 1'b1 ? validData : buffer;
//assign statusAligned_o = aligned;

endmodule