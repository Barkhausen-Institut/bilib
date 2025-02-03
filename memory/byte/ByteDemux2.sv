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

module ByteDemux2 #(
    parameter DATA_BYTE = 4,
    parameter ADDR_SIZE = 32,
    parameter BASE_ADDR = {32'h8000_0000, 32'h1000_0000}
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,

    input   wire logic                      useEnable_i,
    input   wire logic                      useIsWrite_i,
    input   wire logic[DATA_BYTE-1:0]       useWriteMask_i,
    input   wire logic[ADDR_SIZE-1:0]       useAddr_i,
    input   wire logic[DATA_BYTE*8-1:0]     useWriteData_i,
    output  wire logic[DATA_BYTE*8-1:0]     useReadData_o,
    output  wire logic                      useHold_o,
   
    output  wire logic                      aEnable_o,
    output  wire logic                      aIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       aWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       aAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     aWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     aReadData_i,
    input   wire logic                      aHold_i,
   
    output  wire logic                      bEnable_o,
    output  wire logic                      bIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       bWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       bAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     bWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     bReadData_i,
    input   wire logic                      bHold_i
);

wire logic                   memEnable       [2];
wire logic                   memIsWrite      [2];
wire logic [DATA_BYTE-1:0]   memWriteMask    [2];
wire logic [ADDR_SIZE-1:0]   memAddr         [2];
wire logic [DATA_BYTE*8-1:0] memWriteData    [2];
wire logic [DATA_BYTE*8-1:0] memReadData     [2];
wire logic                   memHold         [2];

assign aEnable_o = memEnable[0];
assign aIsWrite_o = memIsWrite[0];
assign aWriteMask_o = memWriteMask[0];
assign aAddr_o = memAddr[0];
assign aWriteData_o = memWriteData[0];
assign memReadData[0] = aReadData_i;
assign memHold[0] = aHold_i;

assign bEnable_o = memEnable[1];
assign bIsWrite_o = memIsWrite[1];
assign bWriteMask_o = memWriteMask[1];
assign bAddr_o = memAddr[1];
assign bWriteData_o = memWriteData[1];
assign memReadData[1] = bReadData_i;
assign memHold[1] = bHold_i;

ByteDemux #(
    .MEMS           (2),
    .DATA_BYTE      (DATA_BYTE),
    .ADDR_SIZE      (ADDR_SIZE),
    .BASE_ADDR      (BASE_ADDR)
) demux (
    .clk_i          (clk_i),
    .rst_i          (rst_i),

    .useEnable_i    (useEnable_i),
    .useIsWrite_i   (useIsWrite_i),
    .useWriteMask_i (useWriteMask_i),
    .useAddr_i      (useAddr_i),
    .useWriteData_i (useWriteData_i),
    .useReadData_o  (useReadData_o),
    .useHold_o      (useHold_o),
   
    .memEnable_o    (memEnable),
    .memIsWrite_o   (memIsWrite),
    .memWriteMask_o (memWriteMask),
    .memAddr_o      (memAddr),
    .memWriteData_o (memWriteData),
    .memReadData_i  (memReadData),
    .memHold_i      (memHold)
);


endmodule