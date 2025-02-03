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

module CellMux2 (
    input  wire logic   i0,
    input  wire logic   i1,
    input  wire logic   s,
    output wire logic   o
);

`ifdef RACYICS
    ri_common_mux2 mux2 (
        .I0(i0),
        .I1(i1),
        .S(s),
        .Z(o)
    );
`else
    assign o = s ? i1 : i0;
`endif

endmodule