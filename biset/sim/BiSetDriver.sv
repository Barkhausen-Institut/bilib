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
import BiSet::*;

module BiSetDriver(
    input   wire logic          clk_i,
    input   wire logic          rst_i,

    //Set interface
    output  wire biSetCtrl      setCtrl_o,
    output  wire biSetData      setWrite_o,
    input   wire biSetReply     setReply_i
);

biSetCtrl cmd;
biSetData out;

assign setWrite_o = out;
assign setCtrl_o = cmd;

initial begin
    cmd = '0;
    out = '0;
end

task automatic read(input biSetAddr addr, output biSetData data);
    @(posedge clk_i);
    cmd = BiSetCtrl(1'b0, addr);
    @(posedge clk_i);
    cmd = '0;
    @(negedge clk_i);
    data = setReply_i;
endtask

task automatic write(input biSetAddr addr, input biSetData data);
    @(posedge clk_i);
    cmd = BiSetCtrl(1'b1, addr);
    out = data;
    @(posedge clk_i);
    cmd = '0;
    out = '0;
endtask


endmodule