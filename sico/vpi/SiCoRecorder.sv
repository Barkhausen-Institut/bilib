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

initial begin
    $SiCoVpiRecorderInit(CHANNEL, val_i, 0);//flags 0:clocked
end

SimTime stime();

always @(*) begin
    longint now;
    now = stime.now(1'b1);

    $SiCoVpiTick(now[32+:32], now[0+:32]);
    $SiCoVpiRecorderPut(CHANNEL, now[32+:32], now[0+:32], val_i, 1'b0); //async
end

endmodule