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
module BiSetRegister #(
    parameter ADDR = 0,
    parameter WIDTH = 32,
    parameter RESET = 0
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,

    output  wire logic[WIDTH-1:0]   val_o,
    output  wire logic              event_o, //write event

    input   wire BiSet::biSetCtrl   setCtrl_i,
    input   wire BiSet::biSetData   setWrite_i,
    output  wire BiSet::biSetReply  setReply_o
);

logic[WIDTH-1:0] store;

logic setMatch;
assign setMatch =
    BiSet::BiSetCtrlAddr(setCtrl_i) == ADDR;

logic setWrite;
assign setWrite =
    setMatch == 1'b1
 && BiSet::BiSetCtrlWriteEnable(setCtrl_i) == 1'b1
  ? 1'b1 : 1'b0;

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)               store <= RESET;
    else if(setWrite == 1'b1)       store <= setWrite_i[WIDTH-1:0];
    else                            store <= store;
end

logic read;
always_ff @(posedge clk_i) read <=
    setMatch == 1'b1
  ? 1'b1 : 1'b0;

assign event_o = setWrite;

assign val_o = store;

assign setReply_o =
    read == 1'b1 ? BiSet::BiSetDataReply({{(32 - WIDTH){1'b0}}, store}) :
    '0;

endmodule