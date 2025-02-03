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

module SiCoIfRecorder #(
    parameter WIDTH = 8,
    parameter CHANNEL = "mon"
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    input   wire logic              valid_i,
    input   wire logic[WIDTH-1:0]   data_i,
    output  wire logic              hold_o
);

import SimHelper::*;

longint cycle;

initial begin
    cycle = -1;
    $SiCoVpiRecorderInit(CHANNEL, data_i, 2);//flags 1:clocked
end

always @( posedge clk_i, posedge rst_i ) begin
    if(rst_i == 1'b1) begin
        cycle <= 1;
    end else begin
        cycle += 1;
        if(valid_i == 1'b1) begin
            $SiCoVpiRecorderPut(CHANNEL, cycle[32+:32], cycle[0+:32], data_i, 2'b11);//force, sync
        end
    end
end

assign hold_o = 1'b0;

endmodule