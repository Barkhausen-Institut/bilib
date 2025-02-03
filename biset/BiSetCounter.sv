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
// register to count pulses on a signal
// reading the register clears the counter
// writing to the register has no effect
// when the counter reaches its MAX value it will remain there until reset

module BiSetCounter #(
    parameter ADDR = 0,
    parameter MAX = (2**32)-1
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,

    input   wire logic              inc_i,

    input   wire BiSet::biSetCtrl   setCtrl_i,
    output  wire BiSet::biSetReply  setReply_o
);

import BiSet::*;

localparam WIDTH = $clog2(MAX);

if(WIDTH > 32)
    PanicModule panic("BiSetCounter WIDTH cannot be greater than 32bit");

logic[WIDTH-1:0] store;

logic setMatch;
assign setMatch =
    BiSetCtrlAddr(setCtrl_i) == ADDR;

logic read;
always_ff @(posedge clk_i) read <=
    BiSetCtrlWriteEnable(setCtrl_i) == 1'b0
 && setMatch == 1'b1
  ? 1'b1 : 1'b0;

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i)                   store <= 0;
    else if(read)               store <= inc_i ? 1 : 0;
    else if(store == MAX)       store <= store;
    else if(inc_i)              store <= store + 1;
    else                        store <= store;
end

assign setReply_o =
    read == 1'b1 ? BiSetDataReply({{(32 - WIDTH){1'b0}}, store}) :
    '0;

endmodule