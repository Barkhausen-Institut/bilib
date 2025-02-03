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
// regsiter to query the status of some module.
// writing anything to BiSetStatus releases a single cycle pulse on event_o to
// signal the module a status request.
// The module's status is delivered to BiSetStatus via the val_i port and stored
// in it when update_i is pulsed.
// BiSetStatus can be configured to reset itself to RESET value upon a read and
// a write to make ensure a value is only read once or that the requested update
// has actually arrived
// UPDATE_MODE specifies how an updated value is combined with the current value
// possibilites are SET, OR, AND, XOR
// reading BiSetStatus will emit an pulse on iter_o, notifying that the current values has been
// collected and a new iteration can be loaded

module BiSetStatus #(
    parameter ADDR = 0,
    parameter WIDTH = 32,
    parameter RESET = 0,
    parameter RESET_ON_READ = 0,
    parameter RESET_ON_WRITE = 1,
    parameter UPDATE_MODE = "SET"
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,

    input   wire logic[WIDTH-1:0]   val_i,
    input   wire logic              update_i,
    output  wire logic              event_o,    //write event
    output  wire logic              iter_o,     //read event

    input   wire BiSet::biSetCtrl   setCtrl_i,
    output  wire BiSet::biSetReply  setReply_o
);

import BiSet::*;

logic[WIDTH-1:0] store;

logic setMatch;
assign setMatch =
    BiSetCtrlAddr(setCtrl_i) == ADDR;

logic setWrite;
assign setWrite =
    setMatch == 1'b1
 && BiSetCtrlWriteEnable(setCtrl_i) == 1'b1
  ? 1'b1 : 1'b0;

logic setRead;
assign setRead =
    setMatch == 1'b1
 && BiSetCtrlWriteEnable(setCtrl_i) == 1'b0
  ? 1'b1 : 1'b0;

logic read;
always_ff @(posedge clk_i) read <= setRead;

logic [WIDTH-1:0] newVal;
if(UPDATE_MODE == "SET")
    assign newVal = val_i;
else if(UPDATE_MODE == "OR")
    assign newVal = val_i | store;
else if(UPDATE_MODE == "AND")
    assign newVal = val_i & store;
else if(UPDATE_MODE == "XOR")
    assign newVal = val_i ^ store;
else
    PanicModule pm();

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)                           store <= RESET;
    else if(update_i == 1'b1)                   store <= newVal;
    else if(setWrite == 1'b1 && RESET_ON_WRITE) store <= RESET;
    else if(read == 1'b1 && RESET_ON_READ)      store <= RESET;
    else                                        store <= store;
end

assign setReply_o =
    read == 1'b1 ? BiSetDataReply({{(32 - WIDTH){1'b0}}, store}) :
    '0;

assign event_o = setWrite;
assign iter_o = setRead;

endmodule