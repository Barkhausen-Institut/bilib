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

////////////////////////////
//
// Clock Generator
//   for Simulation
//
// Produces a clock signal of the given frequency (in MHz).

`default_nettype none
module SimClock #(
    parameter FREQUENCY = 100 * SimHelper::MHZ,
    parameter OFFSET = 0 //psec
) (
    output  wire logic  clk_o
);

import SimHelper::*;
SimTime stime();

logic clk;
longint period;
initial begin
    clk <= 1'b0;
    period = SimHelper::freq2Period(FREQUENCY);
    forever begin
        stime.waitTime(period/2);
        clk <= 1'b1;
        stime.waitTime(period/2);
        clk <= 1'b0;
    end
end
assign clk_o = clk;

endmodule