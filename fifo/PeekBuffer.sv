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

//implements a peek interface in front of an Fifo
// will poll values from a Fifo read interface
// will constantly output one value along with readPeak_o if available
// get next value one cycle lateer by setting readPop_i
// as long as enough 

module PeekBuffer #(
    parameter WIDTH = 16
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    input   wire logic[WIDTH-1:0]   pollData_i,
    output  wire logic              pollEnable_o,
    input   wire logic              pollBusy_i,
    output  wire logic[WIDTH-1:0]   readData_o,
    output  wire logic              readPeek_o,             //output can be read
    input   wire logic              readPop_i               //fetch output
);

//signals
logic   move;       //move back to mem
logic   writing;    //writing to mem/back
logic   pop;        //remove current value
logic   poll;       //want to poll
//storage
logic[WIDTH-1:0]    mem;
logic[WIDTH-1:0]    back;
logic               valid;  //mem is valid
logic               backed; //back buffer is full


assign move = (~valid || pop) && backed;
assign poll = ~valid || pop || (~backed && ~writing);
assign pop = readPop_i && valid;
always_ff @(posedge clk_i) writing <= poll && ~pollBusy_i;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        mem <= '0;
        back <= '0;
        valid <= 1'b0;
        backed <= 1'b0;
    end
    else begin
        if(move)                            mem <= back;        //move from back buffer
        else if(writing && (~valid || pop)) mem <= pollData_i;  //new data
        else                                mem <= mem;         //keep

        if(writing)                         back <= pollData_i;
        else                                back <= back;
    
        if(move || writing)                 valid <= 1'b1;
        else if(pop)                        valid <= 1'b0;
        else                                valid <= valid;
    
        if(move && ~writing)                backed <= 1'b0;
        else if(writing && valid && ~pop)   backed <= 1'b1;
        else                                backed <= backed;
    end
end

//out signals
assign pollEnable_o = poll;
assign readData_o = valid ? mem : '0;
assign readPeek_o = valid;

endmodule