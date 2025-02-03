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
`timescale 1ps/1fs

module CellNand2 (
    input  wire logic   i0,
    input  wire logic   i1,
    output wire logic   o
);

`ifdef RACYICS
    ri_common_nand2 nand2 (
        .A1(i0),
        .A2(i1),
        .ZN(o)
    );
`else
    assign o = ~(i0 & i1);
`endif

endmodule