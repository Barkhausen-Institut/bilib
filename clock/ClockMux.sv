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
`timescale 1ns/100ps

module ClockMux #(
    parameter DELAY = 0
)(
    input  wire clk0_i,
    input  wire clk1_i,
    input  wire sel_i,
    output wire clk_o
);

`ifdef XILINX_FPGA

    BUFGMUX clkMux (
       .I0 (clk0_i),
       .I1 (clk1_i),
       .S  (sel_i),
       .O  (clk_o)
    );

`elsif RACYICS

    ri_common_clkmux
    // synopsys translate_off
        #(.C_DELAY(DELAY))
    // synopsys translate_on
    i_common_clkmux (
        .I0(clk0_i),
        .I1(clk1_i),
        .S(sel_i),
        .Z(clk_o)
    );

`else

    // synopsys translate_off
    generate
        if (DELAY) begin: CLKMUX_DELAY
            assign #DELAY clk_o = sel_i ? clk1_i : clk0_i;
        end
        else begin: CLKMUX_NO_DELAY
    // synopsys translate_on
            assign clk_o = sel_i ? clk1_i : clk0_i;
    // synopsys translate_off
        end
    endgenerate
    // synopsys translate_on

`endif

endmodule 
