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
import SiCoDpi::*;

localparam DPIWIDTH = WIDTH <= 32 ? 32 : WIDTH <= 128 ? 128 : 1;

logic [DPIWIDTH-1:0]    value;
longint                 deadline;
bit                     sync;
longint                 cycle;

initial begin
    cycle = -1;
    deadline = 0;
    value = RST_VAL;
    sync = RST_SYNC ? 1 : 0;
    if(WIDTH <= 32) SiCoDpiPlayerInit32(CHANNEL, value, WIDTH, sync);
    else if(WIDTH <= 128) SiCoDpiPlayerInit128(CHANNEL, value, WIDTH, sync);
    else if(WIDTH <= 1024) SiCoDpiPlayerInit1024(CHANNEL, value, WIDTH, sync);
    else $error("cannot init clocked player bigger than 1024 bit");
end


always @( posedge clk_i ) begin
    cycle += 1;
    if(deadline <= cycle) begin
        longint now;
        now = stime.now(1'b1);
        SiCoDpiTick(now);
        if(WIDTH <= 32) SiCoDpiPlayerGet32(CHANNEL, cycle, value, sync, deadline);
        else if(WIDTH <= 128) SiCoDpiPlayerGet128(CHANNEL, cycle, value, sync, deadline);
        else if(WIDTH <= 1024) SiCoDpiPlayerGet128(CHANNEL, cycle, value, sync, deadline);
        else $error("cannot ue player bigger than 1024 bit");
    end
    if(~sync)
        stime.waitTime(freq2Period(ASYNC_FREQ)); //async wait
    else if(deadline > cycle) 
        stime.waitTime(deadline - cycle); //sync wait
    //$display("player tick:%d", cycle);
end

assign val_o = value[DPIWIDTH-1:0];

endmodule