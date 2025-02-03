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

////////////////////////////
//
// Fifo
//
// Interfaces:
//   Two memory like interfaces to write and read to and from the Fifo
//   For writing set both Enable and Data. If Busy is set write will be ignored
//   To read set Enable when busy is not set. Data will show the next cycle.
//
// Parameters:
//  - WIDTH: item width in bits - default:16
//  - LENGTH: number of items that can be stored - default:16
//  - PROFILE: profile name passed to the BiMem instance
//

`default_nettype none
module Fifo #(
    parameter           PROFILE = "FFdefault",
    parameter unsigned  WIDTH = 16,
    parameter unsigned  LENGTH = 4
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,

    input   wire logic[WIDTH-1:0]           writeData_i,
    input   wire logic                      writeEnable_i,
    output  wire logic                      writeBusy_o,    // => full

    output  wire logic[WIDTH-1:0]           readData_o,
    input   wire logic                      readEnable_i,
    output  wire logic                      readBusy_o,     // => empty

    output  wire logic[$clog2(LENGTH):0]    space_o,
    output  wire logic[$clog2(LENGTH):0]    avail_o
);

localparam unsigned DEPTH = $clog2(LENGTH); //need DEPTH bits to hold LENGTH
localparam unsigned D = DEPTH-1;            //msb of vector to hold LENGTH
localparam unsigned W = WIDTH-1;

//buffer layout

//|         real               |         virtual            |
//| <--      LENGTH        --> |                            |
//|----------------------------|----------------------------|
//      |       |                    |
//   wrs,wrm  rd,rds                 wr

//registers
logic [D+1:0]                   rd;     //read pointer - runs through real and virtual part
logic [D:0]                     rds;    //rd shadow - stays in real part
//logic [D+1:0]                 wr;     //write pointer - runs through real and virtual part - not used in implementation
logic [D:0]                     wrs;    //wr shadow - stays in real part
logic [D+1:0]                   wrm;    //wr mirror - always in opposite part as wr
logic [D+1:0]                   space;  //free items slots
logic [D+1:0]                   avail;  //occupied item slots

//wires - next values for
logic [D+1:0]                   rdN;
logic [D:0]                     rdsN;
logic [D:0]                     wrsN;
logic [D+1:0]                   wrmN;

logic                           reading;    //move read pointer this cycle
logic                           writing;    //move write pointer this cycle

//memory
BiMemTp #(
    .WIDTH          (WIDTH),
    .HEIGHT         (LENGTH),
    .PROFILE        (PROFILE)
) mem (
    .readClk_i      (clk_i),
    .readEnable_i   (reading),
    .readAddr_i     (rds),
    .readData_o     (readData_o),
    .writeClk_i     (clk_i),
    .writeEnable_i  (writing),
    .writeAddr_i    (wrs),
    .writeData_i    (writeData_i)
);

//internal signals
logic                           full;       //buffer is full
logic                           empty;      //buffer is empty


always_comb  begin
    //RD
    if(reading == 1'b0)                     rdN = rd;
    else if(rd == unsigned'(2*LENGTH-1))    rdN = '0;
    else                                    rdN = rd + 1;
    //RD shadow
    if(reading == 1'b0)                     rdsN = rds;
    else if(rds == unsigned'(LENGTH-1))     rdsN = '0;
    else                                    rdsN = rds + 1;
    //WR shadow
    if(writing == 1'b0)                     wrsN = wrs;
    else if(wrs == unsigned'(LENGTH-1))     wrsN = '0;
    else                                    wrsN = wrs + 1;
    //WR mirror
    if(writing == 1'b0)                     wrmN = wrm;
    else if(wrm == unsigned'(2*LENGTH-1))   wrmN = '0;
    else                                    wrmN = wrm + 1;
end

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
                                rd <= 0;
                                rds <= 0;
                                wrs <= 0;
                                wrm <= LENGTH;
                                avail <= 0;
                                space <= LENGTH;
    end else begin
                                rd <= rdN;
                                rds <= rdsN;
                                wrs <= wrsN;
                                wrm <= wrmN;
                                avail <= LENGTH - (rdN - wrmN);
                                space <= rdN - wrmN;
    end
end

assign full = space == 0 ? 1'b1 : 1'b0;
assign empty = avail == 0 ? 1'b1 : 1'b0;
assign reading = readEnable_i == 1'b1 && empty == 1'b0 ? 1'b1 : 1'b0;
assign writing = writeEnable_i == 1'b1 && full == 1'b0 ? 1'b1 : 1'b0;

assign avail_o = avail;
assign space_o = space;
assign writeBusy_o = full;
assign readBusy_o = empty;

endmodule