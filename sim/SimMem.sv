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

module SimMem #(
    parameter unsigned WIDTH = 16,
    parameter unsigned LENGTH = 32,
    parameter unsigned DELAY = 1
) (
    input   wire logic                      aClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] aAddr_i,
    input   wire logic [WIDTH-1:0]          aDataIn_i,
    output  wire logic [WIDTH-1:0]          aDataOut_o,
    input   wire logic                      aEn_i,
    input   wire logic                      aWr_i,

    input   wire logic                      bClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] bAddr_i,
    input   wire logic [WIDTH-1:0]          bDataIn_i,
    output  wire logic [WIDTH-1:0]          bDataOut_o,
    input   wire logic                      bEn_i,
    input   wire logic                      bWr_i
);

localparam unsigned DEPTH = $clog2(WIDTH);
localparam unsigned W = WIDTH-1;
localparam unsigned A = DEPTH-1;

reg [W:0] block [LENGTH-1:0];

logic [W:0] aOutBuf [DELAY];
always @(posedge aClk_i) begin
    logic [W:0] value;
    value = aEn_i ? block[aAddr_i] : '0;
    if(aEn_i == 1'b1 && aWr_i == 1'b1)
        block[aAddr_i] <= aDataIn_i;
    aOutBuf[DELAY-1] <= value;
end
assign aDataOut_o = aOutBuf[0];

logic [W:0] bOutBuf [DELAY];
always @(posedge bClk_i) begin
    logic [W:0] value;
    value = bEn_i ? block[bAddr_i] : '0;
    if(bEn_i == 1'b1 && bWr_i == 1'b1)
        block[bAddr_i] <= bDataIn_i;
    bOutBuf[DELAY-1] <= value;
end
assign bDataOut_o = bOutBuf[0];

task loadHexFile(input string fname, input longint offset);
    $readmemh(fname, block, offset);
endtask

task read(input logic [A:0] addr, output logic [W:0] data);
    data = block[addr];
endtask

task write(input logic [A:0] addr, input logic [W:0] data);
    block[addr] = data;
endtask

endmodule