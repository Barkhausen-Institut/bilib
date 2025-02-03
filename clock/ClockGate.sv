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
`timescale 1ps/1fs

module ClockGate #(
    parameter DELAY = 0
)(
    input  wire logic   clk_i,
    input  wire logic   enable_i,
    output wire logic   clk_o
);

`ifdef XILINX_FPGA

    BUFGCE clkGate (
       .I  (clk_i),
       .CE (enable_i),
       .O  (clk_o)
    );

`elsif RACYICS

    ri_common_clkgate_noscan i_common_clkgate (
        .CP(clk_i),
        .EN(enable_i),
        .CPEN(clk_o)
    );

`else //generic implementation that should work anywhere
 
    logic enableDelayed;
    logic enableSynced;

    assign #DELAY enableDelayed = enable_i;

    always_ff @(negedge clk_i or posedge enableDelayed or negedge enableDelayed) begin
        if(clk_i == 1'b0) begin
            enableSynced <= enableDelayed;
        end
    end

    assign clk_o = clk_i & enableSynced;

`endif

endmodule
