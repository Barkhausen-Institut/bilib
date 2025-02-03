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
module ResetSync (
    input   wire    clk_i,
    input   wire    rst_i,
    output  wire    rst_o
);

`ifdef RACYICS

    logic syncRst_n;
    ri_common_reset_sync sync (
        .clk_i          (clk_i),
        .reset_n_i      (~rst_i),
        .testmode_i     (1'b0),
        .sync_reset_n_o (syncRst_n)
    );
    assign rst_o = ~syncRst_n;

`else

    logic rstN;
    CdcBuffer sync (
        .srcIn_i    (1'b1),
        .dstClk_i   (clk_i),
        .dstRst_i   (rst_i),
        .dstOut_o   (rstN)
    );
    assign rst_o = ~rstN;

`endif


endmodule 
