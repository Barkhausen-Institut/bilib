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

// Memory Interface
// - the very basic

module BiMem #(
    parameter PROFILE = "default",
    parameter WIDTH = 16,
    parameter HEIGHT = 16
) (
    input   wire logic                      clk_i,
    input   wire logic                      enable_i,
    input   wire logic                      isWrite_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  addr_i,
    input   wire logic[WIDTH-1:0]           writeData_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    output  wire logic                      hold_o
);

`ifdef NOPF

    SimMem #(
        .WIDTH      (WIDTH),
        .LENGTH     (HEIGHT)
    ) sim (
        .aClk_i     (clk_i),
        .aAddr_i    (addr_i),
        .aDataIn_i  (writeData_i),
        .aDataOut_o (readData_o),
        .aEn_i      (enable_i),
        .aWr_i      (isWrite_i),

        .bClk_i     (1'b0),
        .bAddr_i    ({$clog2(HEIGHT){1'b0}}),
        .bDataIn_i  ({WIDTH{1'b0}}),
        .bDataOut_o (),
        .bEn_i      (1'b0),
        .bWr_i      (1'b0)
    );
    assign hold_o = 1'b0;

`else

    //implementation has to be provided by the toplevel project trying to use
    //this mem. The profile parameter is used to distinguish between different
    //versions of memories used in different places

    BiMemImpl #(
        .PROFILE        (PROFILE),
        .WIDTH          (WIDTH),
        .HEIGHT         (HEIGHT)
    ) impl (
        .clk_i          (clk_i),
        .enable_i       (enable_i),
        .isWrite_i      (isWrite_i),
        .addr_i         (addr_i),
        .writeData_i    (writeData_i),
        .readData_o     (readData_o),
        .hold_o         (hold_o)
    );

`endif

endmodule