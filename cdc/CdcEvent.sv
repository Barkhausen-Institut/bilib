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
//   Event Buffer
//
// Transfers a single cycle event to the other side regardless of clocks ratio.
// Setting `Request` for one cycle will result in a one cycle signal on `Event`.
// Behavior is only defined if `Ready` is high during the `Request`.

`default_nettype none
module CdcEvent (
    input   wire logic  srcRst_i,
    input   wire logic  srcClk_i,
    input   wire logic  srcRequest_i,
    output  wire logic  srcReady_o,

    input   wire logic  dstRst_i,
    input   wire logic  dstClk_i,
    output  wire logic  dstEvent_o
);

CdcMutex mtx (
    .srcRst_i           (srcRst_i),
    .srcClk_i           (srcClk_i),
    .srcRelease_i       (srcRequest_i),
    .srcLocked_o        (srcReady_o),
    .dstRst_i           (dstRst_i),
    .dstClk_i           (dstClk_i),
    .dstRelease_i       (dstEvent_o),
    .dstLocked_o        (dstEvent_o)
);

endmodule