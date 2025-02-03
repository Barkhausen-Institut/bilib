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
// * Tp - Two port (independent read and write)


module BiMemTp #(
    parameter PROFILE = "default",
    parameter WIDTH = 16,
    parameter HEIGHT = 16
) (
    input   wire logic                      readClk_i,
    input   wire logic                      readEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  readAddr_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    input   wire logic                      writeClk_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  writeAddr_i,
    input   wire logic[WIDTH-1:0]           writeData_i
);

`ifdef NOPF

    SimMem #(
        .WIDTH      (WIDTH),
        .LENGTH     (HEIGHT)
    ) impl (
        .aClk_i     (readClk_i),
        .aAddr_i    (readAddr_i),
        .aDataIn_i  ({WIDTH{1'b0}}),
        .aDataOut_o (readData_o),
        .aEn_i      (readEnable_i),
        .aWr_i      (1'b0),

        .bClk_i     (writeClk_i),
        .bAddr_i    (writeAddr_i),
        .bDataIn_i  (writeData_i),
        .bDataOut_o (),
        .bEn_i      (writeEnable_i),
        .bWr_i      (writeEnable_i)
    );

`else

    //implementation has to be provided by the toplevel project trying to use
    //this mem. The profile parameter is used to distinguish between different
    //versions of memories used in different places

    BiMemTpImpl #(
        .PROFILE        (PROFILE),
        .WIDTH          (WIDTH),
        .HEIGHT         (HEIGHT)
    ) impl (
        .readClk_i      (readClk_i),
        .readEnable_i   (readEnable_i),
        .readAddr_i     (readAddr_i),
        .readData_o     (readData_o),
        .writeClk_i     (writeClk_i),
        .writeEnable_i  (writeEnable_i),
        .writeAddr_i    (writeAddr_i),
        .writeData_i    (writeData_i)
    );

`endif

endmodule