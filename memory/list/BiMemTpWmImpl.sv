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

`default_nettype none

// Memory Interface
// * Wm - Write mask

// implementation template

module BiMemTpWmImpl #(
    parameter PROFILE = "default",
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter MASK = 4
) (
    input   wire logic                      rst_i,
    input   wire logic                      readClk_i,
    input   wire logic                      readEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  readAddr_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    input   wire logic                      writeClk_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[MASK-1:0]            writeMask_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  writeAddr_i,
    input   wire logic[WIDTH-1:0]           writeData_i
);

Spit #(
    .TYPE   ("TW"),
    .PROFILE(PROFILE),
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .MASK   (MASK)
) spit ();

endmodule