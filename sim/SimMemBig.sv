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


module SimMemBig #(
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

localparam unsigned DEPTH = $clog2(LENGTH);
localparam unsigned W = WIDTH-1;
localparam unsigned A = DEPTH-1;

logic [W:0] aOutBuf     [DELAY];

string name;

initial begin
    name = $sformatf("%m");
    $memStoreCreate(name);
end

always_ff @( posedge aClk_i ) begin : portA
    if(aEn_i) begin
        logic [W:0] value;
        if(aWr_i) begin
            write(aAddr_i, value);
            aOutBuf[DELAY-1] <= '0;
        end else begin
            read(aAddr_i, value);
            aOutBuf[DELAY-1] <= value;
        end
    end else
        aOutBuf[DELAY-1] <= aOutBuf[DELAY-1];
end

for(genvar i = 0; i < DELAY-1; i++)
    always @(posedge aClk_i) aOutBuf[i] <= aOutBuf[i+1];

assign aDataOut_o = aOutBuf[0];

task write(input logic [A:0] addr, input logic [W:0] data);
    longint longAddr, longData;
    longAddr = addr;
    longData = data;
    $memStorePut(name, longAddr[32+:32], longAddr[0+:32], longData[32+:32], longData[0+:32]);
endtask

task read(input logic [A:0] addr, output logic [W:0] data);
    longint longAddr, longData;
    longAddr = addr;
    $memStoreGet(name, longAddr[32+:32], longAddr[0+:32], longData[32+:32], longData[0+:32]);
    data = longData;
endtask

task loadHexFile(string fname, int offset);
    //blark
    
endtask




endmodule