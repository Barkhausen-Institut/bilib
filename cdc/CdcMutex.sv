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
// Clock Domain Crossing
//   Signal Mutex
//
// Assures that exactly one clock domain has the mutex `Locked` signal set.
// The locked side can push the lock over by setting the `Release` signal for one cycle.

`default_nettype none
module CdcMutex (
    input   wire logic          srcRst_i,
    input   wire logic          srcClk_i,
    input   wire logic          srcRelease_i,
    output  wire logic          srcLocked_o,

    input   wire logic          dstRst_i,
    input   wire logic          dstClk_i,
    input   wire logic          dstRelease_i,
    output  wire logic          dstLocked_o
);

logic srcForwardSwitch, dstForwardSwitch;
CdcBuffer forwardSwitchPipe (
    .srcIn_i            (srcForwardSwitch),
    .dstClk_i           (dstClk_i),
    .dstRst_i           (dstRst_i),
    .dstOut_o           (dstForwardSwitch)
);

logic dstBackwardSwitch, srcBackwardSwitch;
CdcBuffer backwardSwitchPipe (
    .srcIn_i            (dstBackwardSwitch),
    .dstClk_i           (srcClk_i),
    .dstRst_i           (dstRst_i),
    .dstOut_o           (srcBackwardSwitch)
);


always_ff @( posedge srcClk_i, posedge srcRst_i ) begin
    if(srcRst_i == 1'b1)            srcForwardSwitch <= 1'b0;
    else if(srcRelease_i == 1'b1)   srcForwardSwitch <= ~srcForwardSwitch;
    else                            srcForwardSwitch <= srcForwardSwitch;
end

always_ff @( posedge dstClk_i, posedge dstRst_i ) begin
    if(dstRst_i == 1'b1)            dstBackwardSwitch <= 1'b0;
    else if(dstRelease_i == 1'b1)   dstBackwardSwitch <= ~dstBackwardSwitch;
    else                            dstBackwardSwitch <= dstBackwardSwitch;
end

assign srcLocked_o = srcForwardSwitch == srcBackwardSwitch ? 1'b1 : 1'b0;
assign dstLocked_o = dstBackwardSwitch != dstForwardSwitch ? 1'b1 : 1'b0;

endmodule