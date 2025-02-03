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

//divids a clock by a design time given factor

module ClockDivider #(
    parameter DIVIDER = 2
) (
    input   wire logic      clk_i,
    input   wire logic      rst_i,
    output  wire logic      clk_o
);

`ifdef XILINX_FPGA

    BUFGCE_DIV #(
        .BUFGCE_DIVIDE(DIVIDER) //only 1-8
    ) clkDiv (
       .I   (clk_i),
       .CE  (1'b1),
       .CLR (1'b0),
       .O   (clk_o)
    );

`elsif RACYICS

    ri_common_clkdiv #(
        .DIVIDER(DIVIDER)
    ) i_common_clkdiv (
        .clk_i      (clk_i),
        .reset_n_i  (~rst_i),
        .testmode_i (1'b0),
        .clk_div_o  (clk_o)
    );

`else

    localparam DIVIDER_LENGTH = $clog2(DIVIDER);

    logic[DIVIDER_LENGTH-1:0]   counter;
    logic                       clk;

    always_ff @( posedge clk_i, posedge rst_i ) begin
        if(rst_i == 1'b1)               counter <= '0;
        else if(counter == DIVIDER - 1) counter <= '0;
        else                            counter <= counter + 1;
    end

    always_ff @( posedge clk_i, posedge rst_i) begin
        if(rst_i == 1'b1)                   clk <= 1'b0;
        else if(counter == (DIVIDER/2) - 1) clk <= 1'b0;
        else if(counter == DIVIDER - 1)     clk <= 1'b1;
    end

    assign clk_o = clk;

`endif

endmodule