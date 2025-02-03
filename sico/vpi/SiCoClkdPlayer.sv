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

module SiCoClkdPlayer #(
    parameter WIDTH = 1,
    parameter CHANNEL = "ply",
    parameter RST_SYNC = 1,
    parameter RST_VAL = {WIDTH{1'bX}},
    parameter ASYNC_FREQ = 1_000_000 //1MHz
) (
    input   wire logic              clk_i,
    output  wire logic [WIDTH-1:0]  val_o
);

import SimHelper::*;

SimTime stime();

logic [WIDTH-1:0]   value;
longint             deadline;
bit                 sync;
longint             cycle;

initial begin
    cycle = -1;
    deadline = 0;
    value = RST_VAL;
    sync = RST_SYNC ? 1 : 0;
    $SiCoVpiPlayerInit(CHANNEL, value, sync | 2); //clocked:'d2
end

always @( posedge clk_i ) begin
    cycle += 1;
    if(deadline <= cycle) begin
        longint now;
        now = stime.now(1'b1);
        $SiCoVpiTick(now[32+:32], now[0+:32]);
        $SiCoVpiPlayerGet(CHANNEL, cycle[32+:32], cycle[0+:32], value, sync, deadline[32+:32], deadline[0+:32]);
    end
    if(~sync)
        stime.waitTime(freq2Period(ASYNC_FREQ)); //async wait
    else if(deadline > cycle) 
        stime.waitTime(deadline - cycle); //sync wait
    //$display("player tick:%d", cycle);
end

assign val_o = value;

endmodule