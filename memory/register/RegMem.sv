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

module RegMem #(
    parameter WIDTH = 16,
    parameter HEIGHT = 16
) (
    input   wire logic                      clk_i,
    input   wire logic                      enable_i,
    input   wire logic                      writeEnable_i,
    input   wire logic[$clog2(HEIGHT)-1:0]  addr_i,
    input   wire logic[WIDTH-1:0]           writeData_i,
    output  wire logic[WIDTH-1:0]           readData_o,
    output  wire logic                      hold_o
);

reg [WIDTH-1:0] mem [HEIGHT];
reg [WIDTH-1:0] out;

always @(posedge clk_i) begin
    //read
    if(enable_i)        out <= mem[addr_i];
    else                out <= out;
    //write
    if(writeEnable_i)   mem[addr_i] <= writeData_i;
end

assign readData_o = out;
assign hold_o = 1'b0;

endmodule