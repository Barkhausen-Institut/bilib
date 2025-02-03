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

module OverSampler8 (
    input   wire logic[7:0]         clk_i,
    input   wire logic              data_i,
    output  wire logic              clk_o,
    output  wire logic[7:0]         data_o
);

//we suppose to only do this in simulation and use 3rd party provided modules in
// any kind of silicon
`ifndef SIMULATION
PanicModule panic();
`endif

// clk_i
// 7 ┌-------┐_______
//   __┌-------┐_____
//   ____┌-------┐___
//   ______┌-------┐_
//   ┐_______┌-------
//   --┐_______┌-----
//   ----┐_______┌---
// 0 ------┐_______┌-

// structure
//   7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0   clock pos edge
// 7         _       i       a     b       o          
// 6         _         i     a     b       o                 
// 5               _     i         c       o          
// 4               _       i       c       o          
// 3                 _       i       d     o        
// 2                 _         i     d     o                 
// 1                       _     i         o         
// 0                       _       i       o         

logic[7:0]  in;
logic[7:0]  out;
logic[1:0]  a;
logic[1:0]  b;
logic[1:0]  c;
logic[1:0]  d;

genvar i;
generate
for(i = 0; i < 8; i++) begin
    always_ff @(posedge clk_i[i]) in[i] <= data_i;
end
endgenerate

always_ff @(posedge clk_i[3]) a <= in[7:6];
always_ff @(posedge clk_i[0]) b <= a;
always_ff @(posedge clk_i[0]) c <= in[5:4];
always_ff @(posedge clk_i[7]) d <= in[3:2];
always_ff @(posedge clk_i[4]) out <= {b, c, d, in[1:0]};

assign clk_o = clk_i[4];
assign data_o = out;

endmodule
