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

module ByteDemux #(
    parameter MEMS = 2,
    parameter DATA_BYTE = 4,
    parameter ADDR_SIZE = 32,
    parameter BASE_ADDR = {32'h8000_0000, 32'h1000_0000}
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,

    input   wire logic                      useEnable_i,
    input   wire logic                      useIsWrite_i,
    input   wire logic[DATA_BYTE-1:0]       useWriteMask_i,
    input   wire logic[ADDR_SIZE-1:0]       useAddr_i,
    input   wire logic[DATA_BYTE*8-1:0]     useWriteData_i,
    output  wire logic[DATA_BYTE*8-1:0]     useReadData_o,
    output  wire logic                      useHold_o,
   
    output  wire logic                      memEnable_o    [MEMS],
    output  wire logic                      memIsWrite_o   [MEMS],
    output  wire logic[DATA_BYTE-1:0]       memWriteMask_o [MEMS],
    output  wire logic[ADDR_SIZE-1:0]       memAddr_o      [MEMS],
    output  wire logic[DATA_BYTE*8-1:0]     memWriteData_o [MEMS],
    input   wire logic[DATA_BYTE*8-1:0]     memReadData_i  [MEMS],
    input   wire logic                      memHold_i      [MEMS]
);

typedef logic [$clog2(MEMS):0] route_t;

route_t route, route_r;

always_comb begin
    route = '0; //nothing
    for(int i = 0; i < MEMS; i++) begin
        logic [ADDR_SIZE-1:0] thresh;
        thresh = BASE_ADDR[ADDR_SIZE*i+:ADDR_SIZE];
        if(useAddr_i >= thresh)
            route = i+1;
    end
end
always_ff @(posedge clk_i) route_r <= route;

genvar i;
for(i = 0; i < MEMS; i++) begin
    assign memEnable_o[i] = route == i+1 ? useEnable_i : 1'b0;
    assign memIsWrite_o[i] = route == i+1 ? useIsWrite_i : 1'b0;
    assign memWriteMask_o[i] = route == i+1 ? useWriteMask_i : 1'b0;
    assign memAddr_o[i] = route == i+1 ? useAddr_i : 1'b0;
    assign memWriteData_o[i] = route == i+1 ? useWriteData_i : 1'b0; 
end

assign useHold_o = route != 0 ? memHold_i[route-1] : 1'b0;
assign useReadData_o = route_r != 0 ? memReadData_i[route_r-1] : (DATA_BYTE*8)'(0);

endmodule