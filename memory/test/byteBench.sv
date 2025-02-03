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

module ByteBench;

logic clk;
logic rst;
SiCoCtrl sico (
    .clk_o      (clk),
    .rst_o      (rst)
);
initial begin
    sico.setLoglevel("mem", "debug");
end

logic           enable;
logic           isWrite;
logic [1:0]     wrMask;
logic [31:0]    addr;
logic [15:0]    wrData;
logic [15:0]    rdData;
logic           hold;
ByteMem #(
    .DATA_BYTE      (2)
) mem (
    .clk_i          (clk),
    .enable_i       (enable),
    .isWrite_i      (isWrite),
    .writeMask_i    (wrMask),
    .addr_i         (addr),
    .writeData_i    (wrData),
    .readData_o     (rdData),
    .hold_o         (hold)
);

logic           xEnable;
logic           xIsWrite;
logic [7:0]     xWrMask;
logic [9:0]     xAddr;
logic [63:0]    xWrData;
logic [63:0]    xRdData;
logic           xHold;

ByteConvert #(
    .USE_ADDR_SIZE  (32),
    .USE_DATA_BYTE  (8),
    .MEM_ADDR_SIZE  (32),
    .MEM_DATA_BYTE  (2)
) cvt (
    .clk_i          (clk),
    .rst_i          (rst),
    
    .useEnable_i    (xEnable),
    .useIsWrite_i   (xIsWrite),
    .useWriteMask_i (xWrMask),
    .useAddr_i      ({22'b0, xAddr}),
    .useWriteData_i (xWrData),
    .useReadData_o  (xRdData),
    .useHold_o      (xHold),

    .memEnable_o    (enable),
    .memIsWrite_o   (isWrite),
    .memWriteMask_o (wrMask),
    .memAddr_o      (addr),
    .memWriteData_o (wrData),
    .memReadData_i  (rdData),
    .memHold_i      (hold)
   
);

SiCoBiMemDriverWm #(
    .WIDTH          (64),
    .HEIGHT         (1024),
    .MASK           (8)
) driv (
    .clk_i          (clk),
    .rst_i          (rst),
    .enable_o       (xEnable),
    .isWrite_o      (xIsWrite),
    .writeMask_o    (xWrMask),
    .wrData_o       (xWrData),
    .rdData_i       (xRdData),
    .addr_o         (xAddr),
    .hold_i         (xHold)
);


initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule