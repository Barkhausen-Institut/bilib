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
SimTime stime();

longint cycle;

initial begin
    cycle = -1;
    $SiCoVpiRecorderInit(CHANNEL, val_i, 2);//flags 1:clocked
end

always @( posedge clk_i ) begin
    longint now;
    cycle += 1;
    now = stime.now(1'b1);
    $SiCoVpiTick(now[32+:32], now[0+:32]);
    $SiCoVpiRecorderPut(CHANNEL, cycle[32+:32], cycle[0+:32], val_i, 1'b1);//sync
end

endmodule