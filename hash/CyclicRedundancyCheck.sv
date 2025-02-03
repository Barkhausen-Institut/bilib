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
// Cyclic Redundancy Checker
//
// simple CRC implementation. Input and output are vector with appended
// CRC vector. If the CRC vector is zero on input the output will contain the
// calculated CRC. To check a CRC, input data with CRC appended and check the
// output CRC against '0.
// For the time on calculation `busy_o` will be set. Thereafter the
// result appears at `outData_o` together with an `outValid_o` event.
// not supported: RefIn, RefOut, XorOut

`default_nettype none

module CyclicRedundancyCheck #(   
    parameter unsigned                          DATAWIDTH = 128,
    parameter unsigned                          POLYWIDTH = 8,
    parameter unsigned                          POLY = 8'h7,
    parameter unsigned                          STEPS = 8           //make this many CRC steps in one cycle
) (
    input   wire logic                              clk_i,
    input   wire logic                              rst_i,
    input   wire logic                              inDataValid_i,
    input   wire logic [DATAWIDTH+POLYWIDTH-1:0]    inData_i,
    output  wire logic                              busy_o,
    output  wire logic [DATAWIDTH+POLYWIDTH-1:0]    outData_o,
    output  wire logic                              outValid_o
);

localparam unsigned     D = DATAWIDTH;
localparam unsigned     P = POLYWIDTH;
localparam unsigned     PD = P + D;
localparam unsigned     PPD = PD + P;

//the buffer is {calc_area[P-1:0], data[D-1:0], cechksum[P-1:0]}
function automatic logic[PPD-1:0] CrcStep(input logic[PPD-1:0] data);
    logic [P-1:0]   calc0;
    logic [P-1:0]   calc1;
    logic [P-1:0]   calc2;
    logic [P-1:0]   poly;

    poly = POLY;
    calc0 = {data[PPD-2:PD-1]};
    calc1 = calc0 ^ POLY;
    calc2 = data[PPD-1] == 1'b1 ? calc1 : calc0;
    CrcStep = {calc2, data[PD-2:0], data[PD-1]};
endfunction

logic [PPD-1:0]         dataBuffer;
logic [$clog2(P+D):0]   counter;

logic [PPD-1:0]         dataBufferStep[STEPS];

assign dataBufferStep[0] = CrcStep(dataBuffer);

genvar i;
for(i = 1; i < STEPS; i++) begin
    assign dataBufferStep[i] = CrcStep(dataBufferStep[i-1]);
end

always_ff @( posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
                                        dataBuffer <= '0;
                                        counter <= PD;
    end else if(inDataValid_i == 1'b1 && busy_o == 1'b0) begin
                                        dataBuffer <= {{P{1'b0}}, inData_i};
                                        counter <= '0;
    end else if(counter != PD) begin
                                        dataBuffer <= dataBufferStep[STEPS-1];
                                        counter <= counter + 8;
    end else begin
                                        dataBuffer <= dataBuffer;
                                        counter <= counter;
    end
end

logic busy_r;
always_ff @(posedge clk_i) busy_r <= busy_o;
assign outValid_o = busy_r == 1'b1 && busy_o == 1'b0 ? 1'b1 : 1'b0;
assign busy_o = counter != (PD) ? 1'b1 : 1'b0;
assign outData_o = {dataBuffer[PD-1:P], dataBuffer[PPD-1:PD]};

endmodule