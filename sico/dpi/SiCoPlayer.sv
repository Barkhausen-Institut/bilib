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
import SiCoDpi::*;

localparam DPIWIDTH = WIDTH <= 32 ? 32 : WIDTH <= 128 ? 128 : 1024;

logic [DPIWIDTH-1:0]    value;
longint                 deadline;
bit                     sync;

SimTime stime();

initial begin
    deadline = 0;
    value = RST_VAL;
    sync = RST_SYNC ? 1 : 0;
    if(WIDTH <= 32) SiCoDpiPlayerInit32(CHANNEL, value, WIDTH, sync);
    else if(WIDTH <= 128) SiCoDpiPlayerInit128(CHANNEL, value, WIDTH, sync);
    else if(WIDTH <= 1024) SiCoDpiPlayerInit1024(CHANNEL, value, WIDTH, sync);
    else $error("cannot init player bigger than 1024 bit");
end

initial forever begin
    longint now;
    //int hi, lo;
    now = stime.now(1'b1);
    if(deadline <= now) begin
        if(WIDTH <= 32) SiCoDpiPlayerGet32(CHANNEL, now, value, sync, deadline);
        else if(WIDTH <= 128) SiCoDpiPlayerGet128(CHANNEL, now, value, sync, deadline);
        else if(WIDTH <= 1024) SiCoDpiPlayerGet1024(CHANNEL, now, value, sync, deadline);
        else $error("cannot init player bigger than 1024 bit");
    end
    if(~sync)
        stime.waitTime(freq2Period(ASYNC_FREQ)); //async wait
    else if(deadline > now) 
        stime.waitTime(deadline - now); //sync wait
    //$display("player tick:%d", now);
end

assign val_o = value[WIDTH-1:0];

endmodule