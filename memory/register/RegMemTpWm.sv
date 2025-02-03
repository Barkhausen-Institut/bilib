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

module RegMemTpWm #(
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter MASK = 4         //width of write mask
) (
    input   wire logic                      readClk_i,
    input   wire logic                      readEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  readAddr_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    input   wire logic                      writeClk_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[MASK-1:0]            writeMask_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  writeAddr_i,
    input   wire logic[WIDTH-1:0]           writeData_i
);

integer i;

localparam CHUNK = (WIDTH + MASK - 1) / MASK;   //bits one mask bit masks
localparam REST = WIDTH - ((MASK - 1) * CHUNK); //bits the MSB masks

reg [WIDTH-1:0] mem [HEIGHT];
reg [WIDTH-1:0] out;

//read
always @(posedge readClk_i) begin
    if(readEnable_i)    out <= mem[readAddr_i];
    else                out <= out;
end

//write
always @(posedge writeClk_i) begin
    if(writeEnable_i) begin
        for(i = 0; i < MASK-1; i++) begin
            if(writeMask_i[i])
                mem[writeAddr_i][CHUNK*i+:CHUNK] <= writeData_i[CHUNK*i+:CHUNK];
        end
        //MSB
        if(writeMask_i[MASK-1])
            mem[writeAddr_i][CHUNK*(MASK-1)+:REST] <= writeData_i[CHUNK*(MASK-1)+:REST];
    end
end

assign readData_o = out;

endmodule