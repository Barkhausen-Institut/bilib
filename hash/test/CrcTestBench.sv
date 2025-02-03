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

module CrcTestBench(
    input wire logic clk_i,
    input wire logic rst_i
);

logic           crcInValid;
logic [135:0]   crcIn;
logic           crcBusy;
logic [135:0]   crcOut;
logic           crcValid;

CyclicRedundancyCheck rnd (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .inDataValid_i  (crcInValid),
    .inData_i       (crcIn),
    .busy_o         (crcBusy),
    .outData_o      (crcOut),
    .outValid_o     (crcValid)
);

SiCoClkdPlayer #(
    .WIDTH      (1),
    .CHANNEL    ("inValid")
) inValidPlayer (
    .clk_i      (clk_i),
    .val_o      (crcInValid)
);

SiCoClkdPlayer #(
    .WIDTH      (136),
    .CHANNEL    ("in")
) inPlayer (
    .clk_i      (clk_i),
    .val_o      (crcIn)
);

SiCoClkdRecorder #(
    .WIDTH      (1),
    .CHANNEL    ("busy")
) busyMonitor (
    .clk_i      (clk_i),
    .val_i      (crcBusy)
);

SiCoClkdRecorder #(
    .WIDTH      (136),
    .CHANNEL    ("out")
) outMonitor (
    .clk_i      (clk_i),
    .val_i      (crcOut)
);

SiCoClkdRecorder #(
    .WIDTH      (1),
    .CHANNEL    ("valid")
) validMonitor (
    .clk_i      (clk_i),
    .val_i      (crcValid)
);


endmodule 