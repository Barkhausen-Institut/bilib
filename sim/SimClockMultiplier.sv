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

// Clock Multiplier
//   for Simulation
//
// Produces a clock signal as a multiple of a input clock.
// clocks are not neccessarily aligned

`default_nettype none

module SimClockMultiplier (
    input   wire logic   clk_i,
    output  wire logic   clk_o,
    input   var  real    mult_i
);

import SimHelper::*;

SimTime stime();

//measure clock period
longint periodHistory[10];
int     periodHistoryIndex;
longint period;

task clockSense;
    forever begin
        real lastTime;
        real now;
        real accu;
        real mult;
        lastTime = stime.now(1'b1);
        @clk_i now = stime.now(1'b1);
        //sense clock period
        periodHistory[periodHistoryIndex] = now - lastTime;
        periodHistoryIndex++;
        if(periodHistoryIndex >= 10)
            periodHistoryIndex = 0;
        //sense multi
        if(mult_i < 1) begin
            mult = 1.0;
            if(mult_i != 0.0)
                $display("WARN - mult in ClockMultiplier smaller than 1 -> %f", mult_i);
        end else if(mult_i > 1000) begin
            mult = 1000.0;
            $display("WARN - mult in ClockMultiplier bigger than 1000 -> %f", mult_i);
        end else
            mult = mult_i;
        //calc new output period
        accu = 0;
        foreach(periodHistory[i])
            accu += periodHistory[i];
        period = accu / 10 / mult;
    end
endtask

//generate clock
logic clk;
initial begin
    //init some values
    for(int i = 0; i < 10; i++)
        periodHistory[i] = freq2Period(100 * MHZ);
    periodHistoryIndex = 0;
    period = freq2Period(100 * MHZ);
    //start machinery
    fork
        clockGen();
        clockSense();
    join
end

task clockGen;
    forever begin
        stime.waitTime(period);
        clk = 1'b1;
        stime.waitTime(period);
        clk = 1'b0;
    end
endtask

assign clk_o = clk;

endmodule