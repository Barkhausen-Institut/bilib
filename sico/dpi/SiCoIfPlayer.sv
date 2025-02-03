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

module SiCoIfPlayer #(
    parameter WIDTH = 1,
    parameter CHANNEL = "ply"
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    output  wire logic [WIDTH-1:0]  data_o,
    output  wire logic              valid_o,
    input   wire logic              hold_i
);

import SimHelper::*;
import SiCoDpi::*;

longint             cycle;
logic               valid;
logic [WIDTH-1:0]   value;

initial begin
    if(WIDTH <= 32) SiCoDpiPlayerInit32(CHANNEL, value, WIDTH, 2'b10); //0:sync 1:clocked
    else if(WIDTH <= 128) SiCoDpiPlayerInit128(CHANNEL, value, WIDTH, 2'b10); //0:sync 1:clocked
    else if(WIDTH <= 1024) SiCoDpiPlayerInit1024(CHANNEL, value, WIDTH, 2'b10); //0:sync 1:clocked
    else $error("cannot init IF player bigger than 1024 bit");
end

always @( posedge clk_i, posedge rst_i ) begin
    if(rst_i) begin
        valid <= '0;
        cycle <= '0;
        value <= '0;
    end else begin
        logic               newValid;
        logic [WIDTH-1:0]   newValue;
        newValid = valid;
        newValue = value;
        //use value
        if(valid && ~hold_i) begin
            newValid = 1'b0;
            newValue = '0;
        end
        //get new value
        if(~newValid) begin
            if(WIDTH <= 32) SiCoDpiPlayerGetNext32(CHANNEL, cycle, newValue, newValid);
            else if(WIDTH <= 128) SiCoDpiPlayerGetNext128(CHANNEL, cycle, newValue, newValid);
            else if(WIDTH <= 1024) SiCoDpiPlayerGetNext1024(CHANNEL, cycle, newValue, newValid);
            else $error("cannot use player bigger than 1024 bit");
        end 
        cycle <= cycle + 1;
        value <= newValue;
        valid <= newValid;
    end
end

assign valid_o = valid;
assign data_o = value;

endmodule