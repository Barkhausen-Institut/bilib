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

module ClockSync (
    input   wire logic  clk_i,
    input   wire logic  rst_i,
    output  wire logic  clk_o,
    output  wire logic  rst_o
);

ClockBuffer clkBuf (
    .in_i(clk_i),
    .out_o(clk_o)
);

ResetSync rstSync (
    .clk_i(clk_o),
    .rst_i(rst_i),
    .rst_o(rst_o)
);

endmodule

