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

longint             cycle;
logic               valid;
logic [WIDTH-1:0]   value;

initial begin
    $SiCoVpiPlayerInit(CHANNEL, '0, 2'b10); //clocked, sync
end

always @( posedge clk_i ) begin
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
            $SiCoVpiPlayerGetNext(CHANNEL, cycle[32+:32], cycle[0+:32], newValue, newValid);
            if(newValid)
                $display("sicoifplayer new value: %d @:%t", newValue, $time);
        end 
        cycle <= cycle + 1;
        value <= newValue;
        valid <= newValid;
    end
end
assign valid_o = valid;
assign data_o = value;

endmodule