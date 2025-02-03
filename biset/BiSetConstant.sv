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
module BiSetConstant #(
    parameter int ADDR = 0,
    parameter int VALUE = 0
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,

    input   wire BiSet::biSetCtrl   setCtrl_i,
    output  wire BiSet::biSetReply  setReply_o
);

logic setMatch;
assign setMatch =
    BiSet::BiSetCtrlAddr(setCtrl_i) == ADDR;

logic read;
always_ff @(posedge clk_i) read <=
    BiSet::BiSetCtrlWriteEnable(setCtrl_i) == 1'b0
 && setMatch == 1'b1
  ? 1'b1 : 1'b0;

assign setReply_o =
    read == 1'b1 ? BiSet::BiSetDataReply(VALUE) :
    '0;

endmodule