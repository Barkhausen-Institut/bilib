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

module ByteMem #(
    parameter DATA_BYTE     = 4,
    parameter ADDR_SIZE     = 32,
    parameter MEM_SIZE      = 1024, //in bytes
    parameter MEM_PROFILE   = "default"
) (
    input   wire logic                      clk_i,
    input   wire logic                      enable_i,
    input   wire logic                      isWrite_i,
    input   wire logic[DATA_BYTE-1:0]       writeMask_i,
    input   wire logic[ADDR_SIZE-1:0]       addr_i,
    input   wire logic[(DATA_BYTE*8)-1:0]   writeData_i,
    output  wire logic[(DATA_BYTE*8)-1:0]   readData_o,
    output  wire logic                      hold_o
);

localparam  LINES = MEM_SIZE / DATA_BYTE;
localparam  ADDR_BITS = $clog2(LINES);
localparam  LOW_BIT = $clog2(DATA_BYTE);

BiMemWm #(
    .PROFILE        (MEM_PROFILE),
    .WIDTH          (DATA_BYTE * 8),
    .HEIGHT         (LINES),
    .MASK           (DATA_BYTE)
) mem (
    .clk_i          (clk_i),
    .enable_i       (enable_i),
    .isWrite_i      (isWrite_i),
    .writeMask_i    (writeMask_i),
    .addr_i         (addr_i[LOW_BIT+:ADDR_BITS]),
    .writeData_i    (writeData_i),
    .readData_o     (readData_o),
    .hold_o         (hold_o)
);

endmodule