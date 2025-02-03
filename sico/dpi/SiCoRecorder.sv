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

module SiCoRecorder #(
    parameter WIDTH = 1,
    parameter CHANNEL = "rec"
) (
    input  wire logic [WIDTH-1:0]  val_i
);

import SimHelper::*;
import SiCoDpi::*;

SimTime stime();

initial begin
    if(WIDTH <= 32)     SiCoDpiRecorderInit32  (CHANNEL, val_i, WIDTH, 0);//flags 0:clocked
    if(WIDTH <= 128)    SiCoDpiRecorderInit128 (CHANNEL, val_i, WIDTH, 0);//flags 0:clocked
    if(WIDTH <= 1024)   SiCoDpiRecorderInit1024(CHANNEL, val_i, WIDTH, 0);//flags 0:clocked
    else $error("cannot create recorder bigger than 1024 bit");
end

always_comb begin
    longint now;
    now = stime.now(1'b1);
    if(WIDTH <= 32) begin
        logic [31:0] val;
        val = val_i;
        SiCoDpiRecorderPut32(CHANNEL, now, val_i, WIDTH, 1'b0); //async
    end else if(WIDTH <= 128) begin
        logic [127:0] val;
        val = val_i;
        SiCoDpiRecorderPut128(CHANNEL, now, val_i, WIDTH, 1'b0); //async
    end else if(WIDTH <= 1024) begin
        logic [1023:0] val;
        val = val_i;
        SiCoDpiRecorderPut1024(CHANNEL, now, val_i, WIDTH, 1'b0); //async
    end else
        $error("cannot push value to recorder bigger than 1024 bit");
end

endmodule