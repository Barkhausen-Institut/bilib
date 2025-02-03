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

module BiMemWmImpl #(
    parameter PROFILE = "default",
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter MASK = 4
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,
    input   wire logic                      enable_i,
    input   wire logic                      isWrite_i,
    input   wire logic[MASK-1:0]            writeMask_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  addr_i,
    input   wire logic[WIDTH-1:0]           writeData_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    output  wire logic                      hold_o
);

Spit #(
    .TYPE   ("Wm"),
    .PROFILE(PROFILE),
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .MASK   (MASK)
) spit ();


endmodule