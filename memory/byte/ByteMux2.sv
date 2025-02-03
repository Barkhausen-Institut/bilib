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

module ByteMux2 #(
    parameter DATA_BYTE = 4,
    parameter ADDR_SIZE = 32,
    parameter ARBITRATION = "PRIO",
    parameter HOLDENABLE = 1, //if set to zero stalls are set even if enable ist not set
    parameter REG_ARBITER = 0,
    parameter BREAK_COMB_B = 0
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i, //only needed for REG_ARBITER

    input   wire logic                      aEnable_i,
    input   wire logic                      aIsWrite_i,
    input   wire logic[DATA_BYTE-1:0]       aWriteMask_i,
    input   wire logic[ADDR_SIZE-1:0]       aAddr_i,
    input   wire logic[DATA_BYTE*8-1:0]     aWriteData_i,
    output  wire logic[DATA_BYTE*8-1:0]     aReadData_o,
    output  wire logic                      aHold_o,
   
    input   wire logic                      bEnable_i,
    input   wire logic                      bIsWrite_i,
    input   wire logic[DATA_BYTE-1:0]       bWriteMask_i,
    input   wire logic[ADDR_SIZE-1:0]       bAddr_i,
    input   wire logic[DATA_BYTE*8-1:0]     bWriteData_i,
    output  wire logic[DATA_BYTE*8-1:0]     bReadData_o,
    output  wire logic                      bHold_o,
   
    output  wire logic                      memEnable_o,
    output  wire logic                      memIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       memWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       memAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     memWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     memReadData_i,
    input   wire logic                      memHold_i
);

wire logic                   memEnable       [2];
wire logic                   memIsWrite      [2];
wire logic [DATA_BYTE-1:0]   memWriteMask    [2];
wire logic [ADDR_SIZE-1:0]   memAddr         [2];
wire logic [DATA_BYTE*8-1:0] memWriteData    [2];
wire logic [DATA_BYTE*8-1:0] memReadData     [2];
wire logic                   memHold         [2];


assign memEnable[0] = aEnable_i;
assign memIsWrite[0] = aIsWrite_i;
assign memWriteMask[0] = aWriteMask_i;
assign memAddr[0] = aAddr_i;
assign memWriteData[0] = aWriteData_i;
assign aReadData_o = memReadData[0];
assign aHold_o = memHold[0];

assign memEnable[1] = bEnable_i;
assign memIsWrite[1] = bIsWrite_i;
assign memWriteMask[1] = bWriteMask_i;
assign memAddr[1] = bAddr_i;
assign memWriteData[1] = bWriteData_i;
assign bReadData_o = memReadData[1];
assign bHold_o = memHold[1];

ByteMux #(
    .USER           (2),
    .DATA_BYTE      (DATA_BYTE),
    .ADDR_SIZE      (ADDR_SIZE),
    .ARBITRATION    (ARBITRATION),
    .HOLDENABLE     (HOLDENABLE),
    .REG_ARBITER    (REG_ARBITER),
    .BREAK_COMB_B   (BREAK_COMB_B)
) mux (
    .clk_i          (clk_i),
    .rst_i          (rst_i),

    .useEnable_i    (memEnable),
    .useIsWrite_i   (memIsWrite),
    .useWriteMask_i (memWriteMask),
    .useAddr_i      (memAddr),
    .useWriteData_i (memWriteData),
    .useReadData_o  (memReadData),
    .useHold_o      (memHold),
   
    .memEnable_o    (memEnable_o),
    .memIsWrite_o   (memIsWrite_o),
    .memWriteMask_o (memWriteMask_o),
    .memAddr_o      (memAddr_o),
    .memWriteData_o (memWriteData_o),
    .memReadData_i  (memReadData_i),
    .memHold_i      (memHold_i)

);

endmodule