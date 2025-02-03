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

module Bench;

timeunit 1ps;
timeprecision 1ps;

import SimHelper::*;
import RREnv::*;

SimTime stime();


logic clk;
logic rst;
SiCoCtrl #(
    .LOGLEVEL("info")
) sico(
    .clk_o      (clk),
    .rst_o      (rst)
);

initial begin
    sico.setLoglevel("ifLoop", "debug");
    sico.setLoglevel("DPI", "debug");
    //sico.setLoglevel("clkdLoop", "debug");
    //sico.setLoglevel("loop", "debug");
end

//loopback
logic[15:0] val;
SiCoPlayer #(
    .WIDTH      (16),
    .CHANNEL    ("loop"),
    .RST_SYNC   (1)
) ply (
    .val_o      (val)
);
SiCoRecorder #(
    .WIDTH      (16),
    .CHANNEL    ("loop")
) rec (
    .val_i      (val)
);

//clocked loopback
logic [15:0] cval;
SiCoClkdPlayer #(
    .WIDTH      (16),
    .CHANNEL    ("clkdLoop")
) cply (
    .clk_i      (clk),
    .val_o      (cval)
);
SiCoClkdRecorder #(
    .WIDTH      (16),
    .CHANNEL    ("clkdLoop")
) crec (
    .clk_i      (clk),
    .val_i      (cval)
);

//interface loopback
logic [15:0] ival;
logic ivalValid;
logic ivalHold;
logic [2:0] counter;
logic ivalRec;
always_ff @(posedge clk) begin
    if (rst) counter <= '0;
    else counter <= counter + 1;
end
assign ivalHold = counter == '0 ? 0 : 1;
assign ivalRec = ivalValid & ~ivalHold;

SiCoIfPlayer #(
    .WIDTH      (16),
    .CHANNEL    ("ifLoop")
) iply (
    .clk_i      (clk),
    .rst_i      (rst),
    .data_o     (ival),
    .valid_o    (ivalValid),
    .hold_i     (ivalHold)
);
SiCoIfRecorder #(
    .WIDTH      (16),
    .CHANNEL    ("ifLoop")
) irec (
    .clk_i      (clk),
    .rst_i      (rst),
    .valid_i    (ivalRec),
    .data_i     (ival),
    .hold_o     ()
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars();
end

initial begin
    stime.waitTime(2 * MSEC);
    RRSuccess();
    $fflush;
    $finish;
end


endmodule 