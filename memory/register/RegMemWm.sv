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

module RegMemWm #(
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter MASK = 4         //width of write mask
) (
    input   wire logic                      clk_i,
    input   wire logic                      enable_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[MASK-1:0]            writeMask_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  addr_i,
    input   wire logic[WIDTH-1:0]           writeData_i,
    output  wire logic[WIDTH-1:0]           readData_o
);

integer i;

localparam CHUNK = (WIDTH + MASK - 1) / MASK;   //bits one mask bit masks
localparam REST = WIDTH - ((MASK - 1) * CHUNK); //bits the MSB masks

reg [WIDTH-1:0] mem [HEIGHT];
reg [WIDTH-1:0] out;

always @(posedge clk_i) begin
    //read
    if(enable_i)        out <= mem[addr_i];
    else                out <= out;
    //write
    if(writeEnable_i) begin
        for(i = 0; i < MASK-1; i++) begin
            if(writeMask_i[i])
                mem[addr_i][CHUNK*i+:CHUNK] <= writeData_i[CHUNK*i+:CHUNK];
        end
        //MSB
        if(writeMask_i[MASK-1])
            mem[addr_i][CHUNK*(MASK-1)+:REST] <= writeData_i[CHUNK*(MASK-1)+:REST];
    end
end

assign readData_o = out;

endmodule