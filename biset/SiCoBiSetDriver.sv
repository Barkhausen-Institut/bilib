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

module SiCoBiSetDriver #(
    parameter CHANNEL = "biset"
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    output  wire BiSet::biSetCtrl   ctrl_o,
    output  wire BiSet::biSetData   write_o,
    input   wire BiSet::biSetReply  reply_i
);

logic request;
logic request_r;
always_ff @(posedge clk_i) request_r <= request;
BiSet::biSetCtrl ctrl;
BiSet::biSetData data;

SiCoIfPlayer #(
    .CHANNEL        (CHANNEL),
    .WIDTH          (BiSet::BISET_CTRLLEN + BiSet::BISET_DATALEN)
) ply (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .data_o         ({ctrl, data}),
    .valid_o        (request),
    .hold_i         (1'b0)
);

SiCoIfRecorder #(
    .CHANNEL        (CHANNEL),
    .WIDTH          (BiSet::BISET_REPLYLEN)
) rec (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .valid_i        (request_r),
    .data_i         (reply_i),
    .hold_o()
);

assign ctrl_o = request ? ctrl : '0;
assign write_o = request ? data : '0;

endmodule