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

module Bench;

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
logic [3:0]     addr;
logic [15:0]    wrData;
logic [15:0]    rdData;
logic           hold;
BiMem mem (
    .clk_i          (clk),
    .enable_i       (enable),
    .isWrite_i      (isWrite),
    .addr_i         (addr),
    .writeData_i    (wrData),
    .readData_o     (rdData),
    .hold_o         (hold)
);

SiCoBiMemDriver driv (
    .clk_i          (clk),
    .rst_i          (rst),
    .enable_o       (enable),
    .isWrite_o      (isWrite),
    .wrData_o       (wrData),
    .rdData_i       (rdData),
    .addr_o         (addr),
    .hold_i         (hold)
);

logic           enable2;
logic           isWrite2;
logic [3:0]     addr2;
logic [3:0]     mask2;
logic [15:0]    wrData2;
logic [15:0]    rdData2;
logic           hold2;
BiMemWm mem2 (
    .clk_i          (clk),
    .enable_i       (enable2),
    .isWrite_i      (isWrite2),
    .writeMask_i    (mask2),
    .addr_i         (addr2),
    .writeData_i    (wrData2),
    .readData_o     (rdData2),        
    .hold_o         (hold2)
);

SiCoBiMemDriverWm #(
    .CHANNEL        ("mem2")
) driv2 (
    .clk_i          (clk),
    .rst_i          (rst),
    .enable_o       (enable2),
    .isWrite_o      (isWrite2),
    .writeMask_o    (mask2),
    .wrData_o       (wrData2),
    .rdData_i       (rdData2),
    .addr_o         (addr2),
    .hold_i         (hold2)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule