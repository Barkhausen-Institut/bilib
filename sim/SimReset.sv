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
// Reset Generator
//   for Simulation
//
// Produces a Reset after and for a specific amount of time .

`default_nettype none

module SimReset #(
    parameter   OFFSET = 0, //psec
    parameter   LENGTH = SimHelper::USEC
) (
    output  wire logic  rst_o
);

SimTime stime();

logic rst;
initial begin
    rst <= 1'b0;
    stime.waitTime(OFFSET);
    rst <= 1'b1;
    stime.waitTime(LENGTH);
    rst <= 1'b0;
end

assign rst_o = rst;

endmodule