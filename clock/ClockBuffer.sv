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

module ClockBuffer #(
    parameter DELAY = 0
) (
    input wire logic    in_i,
    output wire logic   out_o
);

`ifdef XILINX_FPGA
    BUFG clkBuf (
        .I(in_i),
        .O(out_o)
    );

`elsif RACYICS
    ri_common_clkbuf clkBuf (
        .I (in_i),
        .Z (out_o)
    );
`else

    assign #DELAY out_o = in_i;

`endif

endmodule