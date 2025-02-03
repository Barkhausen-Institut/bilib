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

`timescale 1ps/1ps
//timeunit 1ps / 1ps;

module SiCoPlayer #(
    parameter WIDTH = 1,
    parameter CHANNEL = "ply",
    parameter RST_SYNC = 1,
    parameter RST_VAL = {WIDTH{1'bX}},
    parameter ASYNC_FREQ = 1_000_000 //1MHz
) (
    output  wire logic [WIDTH-1:0]  val_o
);

import SimHelper::*;

longint now;
SimTime stime();

logic [WIDTH-1:0]   value;
longint             deadline;
bit                 sync;

initial begin
    deadline = 0;
    value = RST_VAL;
    sync = RST_SYNC;
    $SiCoVpiPlayerInit(CHANNEL, value, sync);
end

initial forever begin
    longint now;
    int deadHi, deadLo;
    now = stime.now(1'b1);
    if(deadline <= now) begin
        $SiCoVpiTick(now[32+:32], now[0+:32]);
        $SiCoVpiPlayerGet(CHANNEL, now[32+:32], now[0+:32], value, sync, deadHi, deadLo);
        deadline = {deadHi, deadLo};
    end
    if(~sync) begin
        stime.waitTime(freq2Period(ASYNC_FREQ)); //async wait
    end else if(deadline > now)  begin
        stime.waitTime(deadline - now); //sync wait
    end
    //$display("player tick:%d", now);
end

assign val_o = value;

endmodule