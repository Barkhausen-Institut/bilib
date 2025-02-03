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

module SiCoBiMemDriverWm #(
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter MASK = 4,
    parameter CHANNEL = "mem"
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,
    output  wire logic                      enable_o,
    output  wire logic                      isWrite_o,
    output  wire logic[MASK-1:0]            writeMask_o,
    output  wire logic[WIDTH-1:0]           wrData_o,
    input   wire logic[WIDTH-1:0]           rdData_i,
    output  wire logic[$clog2(HEIGHT)-1:0]  addr_o,
    input   wire logic                      hold_i
);

localparam REQUEST_WIDTH = 1 + $clog2(HEIGHT) + WIDTH + MASK;
localparam RESPONSE_WIDTH = WIDTH;
localparam ADDR = $clog2(HEIGHT);

//request
logic [REQUEST_WIDTH-1:0]   request;
logic                       requestValid;
logic                       requestHold;
SiCoIfPlayer #(
    .WIDTH(REQUEST_WIDTH),
    .CHANNEL(CHANNEL)
) ply (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_o     (request),
    .valid_o    (requestValid),
    .hold_i     (requestHold)
);

logic [REQUEST_WIDTH-1:0]   rqRaw;
logic [ADDR-1:0]            rqAddr;
logic [WIDTH-1:0]           rqData;
logic [MASK-1:0]            rqMask;
logic                       rqIsWrite;
logic                       rqValid; //A request is going on
logic                       rqFinish; //The request is finishing this cycle
logic                       rqFinishing; //The request is finishing the next cycle

always_ff @( posedge clk_i ) begin
    if(rst_i) begin
        rqRaw <= '0;
        rqValid <= 1'b0;
    end else if(rqFinishing || ~rqValid) begin
        if(requestValid) begin
            rqRaw <= request;
            rqValid <= 1'b1;
        end else begin
            rqRaw <= '0;
            rqValid <= 1'b0;
        end
    end else begin
        rqRaw <= rqRaw;
        rqValid <= rqValid;
    end
    rqFinish <= rqFinishing;
end
assign requestHold = rqValid & ~rqFinishing;
assign {
    rqIsWrite,
    rqAddr,
    rqData,
    rqMask
} = rqRaw;
assign rqFinishing = rqValid & ~hold_i;

assign enable_o = rqValid;
assign isWrite_o = rqIsWrite;
assign wrData_o = rqIsWrite ? rqData : '0;
assign addr_o = rqAddr;
assign writeMask_o = rqMask;

logic [RESPONSE_WIDTH-1:0]  response;
logic                       responseValid;
SiCoIfRecorder #(
    .WIDTH(RESPONSE_WIDTH),
    .CHANNEL(CHANNEL)
) rec (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .valid_i    (responseValid),
    .data_i     (response),
    .hold_o()
);

assign responseValid = rqFinish;
assign response = rdData_i;

endmodule