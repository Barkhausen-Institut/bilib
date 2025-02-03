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
//   Data Vector Gate
//
// Safely transfers a data vector through a gate. Works like a FIFO of size one.
// When the gate is `Open` each side can `Read`/`Write` a data vector.
// reading/writing automatically shifts gate access to the other side.
// That means the own `Open` goes low and the opposites `Open` becomes high
// after some time.

`default_nettype none

module CdcGate #(
    parameter unsigned          WIDTH = 8
) (
    input   wire logic              srcRst_i,
    input   wire logic              srcClk_i,
    input   wire logic              srcWrite_i,
    input   wire logic[WIDTH-1:0]   srcData_i,
    output  wire logic              srcOpen_o,

    input   wire logic              dstRst_i,
    input   wire logic              dstClk_i,
    input   wire logic              dstRead_i,
    output  wire logic[WIDTH-1:0]   dstData_o,
    output  wire logic              dstOpen_o
);

localparam unsigned W =         WIDTH-1;

logic dstLocked, dstLocked_r;
always_ff @( posedge dstClk_i ) dstLocked_r <= dstLocked;

CdcMutex mtx (
    .srcRst_i           (srcRst_i),
    .srcClk_i           (srcClk_i),
    .srcRelease_i       (srcWrite_i),
    .srcLocked_o        (srcOpen_o),
    .dstRst_i           (dstRst_i),
    .dstClk_i           (dstClk_i),
    .dstRelease_i       (dstRead_i),
    .dstLocked_o        (dstLocked)
);

logic [W:0] srcTransfer, dstTransfer;

always_ff @( posedge srcClk_i, posedge srcRst_i ) begin
    if(srcRst_i == 1'b1)        srcTransfer <= '0;
    else if(srcWrite_i == 1'b1) srcTransfer <= srcData_i;
    else                        srcTransfer <= srcTransfer;
end

always_ff @( posedge dstClk_i, posedge dstRst_i ) begin
    if(dstRst_i == 1'b1)        dstTransfer <= '0;
    else if(dstLocked == 1'b1)  dstTransfer <= srcTransfer;
    else                        dstTransfer <= dstTransfer;
end

assign dstData_o = dstTransfer;
assign dstOpen_o = dstLocked_r == 1'b1 && dstLocked == 1'b1 ? 1'b1 : 1'b0;

endmodule

