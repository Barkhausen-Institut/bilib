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

module PrngTestBench(
    input wire logic clk_i,
    input wire logic rst_i
);

logic [15:0] val;
PseudoRandomNumberGenerator rnd (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .num_o      (val)
);

SiCoRecorder #(
    .WIDTH      (16),
    .CHANNEL    ("mon")
) monitor (
    .val_i      (val)
);


endmodule 