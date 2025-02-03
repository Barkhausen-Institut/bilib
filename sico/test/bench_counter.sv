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

`ifdef AUTOHOLD
    localparam HOLDTIME = 1 * SimHelper::NSEC;
`else
    localparam HOLDTIME = 0;
`endif

logic clk;
logic rst;
SiCoCtrl #(
    .HOLD_TIME  (HOLDTIME)
) sico (
    .clk_o  (clk),
    .rst_o  (rst)
);

logic [63:0] counter;

always_ff @( clk ) begin : counterInc
    if(rst)
        counter <= '0;
    else
        counter <= counter + 1;
end

endmodule 