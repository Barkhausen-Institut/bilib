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


module ClockInverter #(
    parameter DELAY = 0
)(
    input  wire logic clk_i,
    output wire logic clk_o
);

    wire logic clk_n;

    // synopsys translate_off
    generate
        if (DELAY) begin: WITH_DELAY
            assign #DELAY clk_n = ~clk_i;
        end
        else begin: NO_DELAY
    // synopsys translate_on
            assign clk_n = ~clk_i;
    // synopsys translate_off
        end
    endgenerate
    // synopsys translate_on

    assign clk_o = clk_n;

endmodule
