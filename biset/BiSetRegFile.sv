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

module BiSetRegFile #(
    parameter ADDR = 1,
    parameter LENGTH = 2,
    parameter RESET = 0
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,

    output  wire logic[31:0]        val_o[LENGTH],
    output  wire logic              event_o[LENGTH], //write event

    input   wire BiSet::biSetCtrl   setCtrl_i,
    input   wire BiSet::biSetData   setWrite_i,
    output  wire BiSet::biSetReply  setReply_o
);

import BiSet::*;

biSetReply setReplys[LENGTH];

genvar i;
generate 
for(i = 0; i < LENGTH; i++) begin
    BiSetRegister #(
        .ADDR       (ADDR + i),
        .WIDTH      (32),
        .RESET      (RESET)
    ) setRegister (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .val_o      (val_o[i]),
        .event_o    (event_o[i]),
        .setCtrl_i  (setCtrl_i),
        .setWrite_i (setWrite_i),
        .setReply_o (setReplys[i])
    );
end
endgenerate 

BiSetReplyMux #(
    .LENGTH         (LENGTH)
) replyMux (
    .in_i           (setReplys),
    .out_o          (setReply_o)
);

endmodule