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

module ByteDemux4 #(
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
    input   wire logic                      bHold_i,
   
    output  wire logic                      cEnable_o,
    output  wire logic                      cIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       cWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       cAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     cWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     cReadData_i,
    input   wire logic                      cHold_i,
   
    output  wire logic                      dEnable_o,
    output  wire logic                      dIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       dWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       dAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     dWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     dReadData_i,
    input   wire logic                      dHold_i
);

wire logic                   memEnable       [4];
wire logic                   memIsWrite      [4];
wire logic [DATA_BYTE-1:0]   memWriteMask    [4];
wire logic [ADDR_SIZE-1:0]   memAddr         [4];
wire logic [DATA_BYTE*8-1:0] memWriteData    [4];
wire logic [DATA_BYTE*8-1:0] memReadData     [4];
wire logic                   memHold         [4];

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

assign cEnable_o = memEnable[2];
assign cIsWrite_o = memIsWrite[2];
assign cWriteMask_o = memWriteMask[2];
assign cAddr_o = memAddr[2];
assign cWriteData_o = memWriteData[2];
assign memReadData[2] = cReadData_i;
assign memHold[2] = cHold_i;

assign dEnable_o = memEnable[3];
assign dIsWrite_o = memIsWrite[3];
assign dWriteMask_o = memWriteMask[3];
assign dAddr_o = memAddr[3];
assign dWriteData_o = memWriteData[3];
assign memReadData[3] = dReadData_i;
assign memHold[3] = dHold_i;

ByteDemux #(
    .MEMS           (4),
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