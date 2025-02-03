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
// - the very basic

//implementation template

module BiMemImpl #(
    parameter PROFILE = "default",
    parameter WIDTH = 16,
    parameter HEIGHT = 16
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,
    input   wire logic                      enable_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  addr_i,
    input   wire logic[WIDTH-1:0]           data_i,
    output  wire logic[WIDTH-1:0]           data_o
);

//`ifdef PROFILE_1

//`elsif PROFILE_2

//`else

PanicModule panic("Profile is not known");

//`endif

endmodule