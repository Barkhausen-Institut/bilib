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


module SimMemMask #(
    parameter unsigned WIDTH = 16,
    parameter unsigned LENGTH = 32,
    parameter unsigned DELAY = 1,
    parameter unsigned MASK = 2     //number of mask bits
) (
    input   wire logic                      aClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] aAddr_i,
    input   wire logic [WIDTH-1:0]          aDataIn_i,
    output  wire logic [WIDTH-1:0]          aDataOut_o,
    input   wire logic                      aEn_i,
    input   wire logic [MASK-1:0]           aWr_i,

    input   wire logic                      bClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] bAddr_i,
    input   wire logic [WIDTH-1:0]          bDataIn_i,
    output  wire logic [WIDTH-1:0]          bDataOut_o,
    input   wire logic                      bEn_i,
    input   wire logic [MASK-1:0]           bWr_i
);

localparam unsigned DEPTH = $clog2(WIDTH);
localparam unsigned W = WIDTH-1;
localparam unsigned A = DEPTH-1;

localparam CHUNK = (WIDTH + MASK - 1) / MASK;   //bits one mask bit masks
localparam REST = WIDTH - ((MASK - 1) * CHUNK); //bits the MSB masks

logic [W:0] block [LENGTH-1:0];

logic [WIDTH-1:0] aBitMask;
genvar a;
for(a = 0; a < MASK-1; a++)
    assign aBitMask[(CHUNK*a)+:(CHUNK)] = {CHUNK{aWr_i[a]}};
assign aBitMask[(CHUNK*(MASK-1))+:REST] = {REST{aWr_i[MASK-1]}};

logic [W:0] aOutBuf [DELAY];
always @(posedge aClk_i) begin
    logic [W:0] aValue;
    aValue = aEn_i ? block[aAddr_i] : '0;
    if(aEn_i == 1'b1 && |aWr_i == 1'b1)
        block[aAddr_i] <= (aValue & ~aBitMask) | (aBitMask & aDataIn_i);
    aOutBuf[DELAY-1] <= aValue;
end
assign aDataOut_o = aOutBuf[0];


logic [WIDTH-1:0] bBitMask;
genvar b;
for(b = 0; b < MASK-1; b++)
    assign bBitMask[(CHUNK*b)+:(CHUNK)] = {CHUNK{bWr_i[b]}};
assign bBitMask[(CHUNK*(MASK-1))+:REST] = {REST{bWr_i[MASK-1]}};

logic [W:0] bOutBuf [DELAY];
always @(posedge bClk_i) begin
    logic [W:0] bValue;
    bValue = bEn_i ? block[bAddr_i] : '0;
    if(bEn_i == 1'b1 && |bWr_i == 1'b1)
        block[bAddr_i] <= (bValue & ~bBitMask) | (bBitMask & bDataIn_i);
    bOutBuf[DELAY-1] <= bValue;
end
assign bDataOut_o = bOutBuf[0];



endmodule