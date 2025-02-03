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

import _8b10b::*;

module Bench;

logic       clk;
SimClock #(
    .FREQUENCY      (1024 * SimHelper::MHZ)
) clkGen (
    .clk_o          (clk)
);

logic rst;
SimReset rstGen(
    .rst_o          (rst)
);

logic [7:0] dcoClk;
SimClockDividerDco #(8) dcoClkGen (
    .clk_i          (clk),
    .rst_i          (rst),
    .clk_o          (dcoClk)
);

logic dcoRst;
ResetGenerator docRstGen (
    .sysClk_i       (clk),
    .sysRst_i       (rst),
    .genClk_i       (dcoClk[0]),
    .genRst_o       (dcoRst),
    .done_i         (~rst)
);

logic       dataClk;
SimClock #(
    .FREQUENCY      (1030.0/8 * SimHelper::MHZ)
) dataClkGen (
    .clk_o          (dataClk)
);

pair10  p10;
logic   pStall;
always @(posedge dataClk) begin
    if(rst == 1'b1)             p10 <= 'b11000001010110101001;
    else if(pStall == 1'b0)     p10 <= $urandom;
    else                        p10 <= p10;
end

logic serData;
_8b10bSerialize ser (
    .clk_i          (dataClk),
    .rst_i          (rst),
    .parallel_i     (p10),
    .stall_o        (pStall),
    .serial_o       (serData)
);

logic       sampleClk;
logic [7:0] sample;

OverSampler8 ov (
    .clk_i          (dcoClk),
    .data_i         (serData),
    .clk_o          (sampleClk),
    .data_o         (sample)
);

logic [2:0] bits;
logic [1:0] bitsValid;
DataRecover8 rec (
    .clk_i          (sampleClk),
    .rst_i          (dcoRst),
    .data_i         (sample),
    .ddr_i          (1'b0),
    .data_o         (bits),
    .valid_o        (bitsValid)
);

pair10 pOut;
logic  pOutValid;
_8b10bDeserialize des (
    .clk_i          (sampleClk),
    .rst_i          (dcoRst),
    .serial_i       (bits),
    .valid_i        (bitsValid),
    .enReAlign_i    (1'b0),
    .parallel_o     (pOut),
    .valid_o        (pOutValid)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;

    SimHelper::waitTime(SimHelper::MSEC);
    $finish;
end

endmodule 