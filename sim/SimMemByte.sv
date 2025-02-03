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

module SimMemByte #(
    parameter unsigned WIDTH = 16,
    parameter unsigned LENGTH = 32,
    parameter unsigned DELAY = 1
) (
    input   wire logic                      aClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] aAddr_i,
    input   wire logic [WIDTH-1:0]          aDataIn_i,
    output  wire logic [WIDTH-1:0]          aDataOut_o,
    input   wire logic                      aEn_i,
    input   wire logic [((WIDTH+7)/8)-1:0]  aWr_i,

    input   wire logic                      bClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] bAddr_i,
    input   wire logic [WIDTH-1:0]          bDataIn_i,
    output  wire logic [WIDTH-1:0]          bDataOut_o,
    input   wire logic                      bEn_i,
    input   wire logic [((WIDTH+7)/8)-1:0]  bWr_i
);

SimMemMask #(
    .WIDTH      (WIDTH),
    .LENGTH     (LENGTH),
    .MASK       ((WIDTH+7)/8)
) memBit (
    .aClk_i     (aClk_i),
    .aAddr_i    (aAddr_i),
    .aDataIn_i  (aDataIn_i),
    .aDataOut_o (aDataOut_o),
    .aEn_i      (aEn_i),
    .aWr_i      (aWr_i),

    .bClk_i     (bClk_i),
    .bAddr_i    (bAddr_i),
    .bDataIn_i  (bDataIn_i),
    .bDataOut_o (bDataOut_o),
    .bEn_i      (bEn_i),
    .bWr_i      (bWr_i)
);

endmodule