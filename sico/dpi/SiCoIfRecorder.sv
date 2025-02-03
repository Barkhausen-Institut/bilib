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

module SiCoIfRecorder #(
    parameter WIDTH = 8,
    parameter CHANNEL = "mon"
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    input   wire logic              valid_i,
    input   wire logic[WIDTH-1:0]   data_i,
    output  wire logic              hold_o
);

import SimHelper::*;
import SiCoDpi::*;

longint cycle;

initial begin
    cycle = -1;
    if(WIDTH <= 32)     SiCoDpiRecorderInit32  (CHANNEL, data_i, WIDTH, 2);//flags 1:clocked
    if(WIDTH <= 128)    SiCoDpiRecorderInit128 (CHANNEL, data_i, WIDTH, 2);//flags 1:clocked
    if(WIDTH <= 1024)   SiCoDpiRecorderInit1024(CHANNEL, data_i, WIDTH, 2);//flags 1:clocked
    else $error("cannot create recorder bigger than 1024 bit");
end

always @( posedge clk_i, posedge rst_i ) begin
    if(rst_i == 1'b1) begin
        cycle <= 1;
    end else begin
        cycle += 1;
        if(valid_i == 1'b1) begin
            if(WIDTH <= 32) begin
                logic [31:0] val;
                val = data_i;
                SiCoDpiRecorderPut32(CHANNEL, cycle, data_i, WIDTH, 2'b11); //0:sync 1:force
            end else if(WIDTH <= 128) begin
                logic [127:0] val;
                val = data_i;
                SiCoDpiRecorderPut128(CHANNEL, cycle, data_i, WIDTH, 2'b11); //0:sync 1:force
            end else if(WIDTH <= 1024) begin
                logic [1023:0] val;
                val = data_i;
                SiCoDpiRecorderPut1024(CHANNEL, cycle, data_i, WIDTH, 2'b11); //0:sync 1:force
            end else
                $error("cannot push value to recorder bigger than 1024 bit");
        end
    end
end

assign hold_o = 1'b0;

endmodule