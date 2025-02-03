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

module SiCoClkdRecorder #(
    parameter WIDTH = 1,
    parameter CHANNEL = "rec"
) (
    input  wire logic               clk_i,
    input  wire logic [WIDTH-1:0]   val_i
);

import SimHelper::*;
import SiCoDpi::*;

longint cycle;

initial begin
    cycle = -1;
    if(WIDTH <= 32)     SiCoDpiRecorderInit32  (CHANNEL, val_i, WIDTH, 2);//flags 1:clocked
    if(WIDTH <= 128)    SiCoDpiRecorderInit128 (CHANNEL, val_i, WIDTH, 2);//flags 1:clocked
    if(WIDTH <= 1024)   SiCoDpiRecorderInit1024(CHANNEL, val_i, WIDTH, 2);//flags 1:clocked
    else $error("cannot create recorder bigger than 1024 bit");
end

initial forever begin
    @( posedge clk_i );
    cycle += 1;
    if(WIDTH <= 32) begin
        logic [31:0] val;
        val = val_i;
        SiCoDpiRecorderPut32(CHANNEL, cycle, val_i, WIDTH, 1'b1); //0:sync 1:force
    end else if(WIDTH <= 128) begin
        logic [127:0] val;
        val = val_i;
        SiCoDpiRecorderPut128(CHANNEL, cycle, val_i, WIDTH, 1'b1); //0:sync 1:force
    end else if(WIDTH <= 1024) begin
        logic [1023:0] val;
        val = val_i;
        SiCoDpiRecorderPut1024(CHANNEL, cycle, val_i, WIDTH, 1'b1); //0:sync 1:force
    end else
        $error("cannot push value to recorder bigger than 128 bit");
end

endmodule