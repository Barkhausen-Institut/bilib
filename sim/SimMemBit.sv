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


module SimMemBit #(
    parameter unsigned WIDTH = 16,
    parameter unsigned LENGTH = 32,
    parameter unsigned DELAY = 1
) (
    input   wire logic                      aClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] aAddr_i,
    input   wire logic [WIDTH-1:0]          aDataIn_i,
    output  wire logic [WIDTH-1:0]          aDataOut_o,
    input   wire logic                      aEn_i,
    input   wire logic [WIDTH-1:0]          aWr_i,

    input   wire logic                      bClk_i,
    input   wire logic [$clog2(LENGTH)-1:0] bAddr_i,
    input   wire logic [WIDTH-1:0]          bDataIn_i,
    output  wire logic [WIDTH-1:0]          bDataOut_o,
    input   wire logic                      bEn_i,
    input   wire logic [WIDTH-1:0]          bWr_i
);

localparam unsigned DEPTH = $clog2(WIDTH);
localparam unsigned W = WIDTH-1;
localparam unsigned A = DEPTH-1;

logic [W:0] block [LENGTH-1:0];

genvar wr_bit, rd_bit;


//Port A
generate
for (wr_bit=0; wr_bit<WIDTH; wr_bit=wr_bit+1) begin: block_awrite
    always @(posedge aClk_i) begin
        if (aEn_i == 1'b1 && aWr_i[wr_bit] == 1'b1)
            block[aAddr_i][wr_bit] <= aDataIn_i[wr_bit];
    end
end
endgenerate

logic [W:0] aOutBuf [DELAY];
generate
for (rd_bit=0; rd_bit<WIDTH; rd_bit=rd_bit+1) begin: block_aread
    always @(posedge aClk_i) begin
        if(aEn_i == 1'b1) begin
            if(aWr_i[rd_bit] == 1'b0)
                aOutBuf[DELAY-1][rd_bit] <= block[aAddr_i][rd_bit];
            else
                aOutBuf[DELAY-1][rd_bit] <= aDataIn_i[rd_bit];
        end
    end
end
endgenerate

for(genvar i = 0; i < DELAY-1; i++)
    always @(posedge aClk_i) aOutBuf[i] <= aOutBuf[i+1];

assign aDataOut_o = aOutBuf[0];


//Port B
generate
for (wr_bit=0; wr_bit<WIDTH; wr_bit=wr_bit+1) begin: block_bwrite
    always @(posedge bClk_i) begin
        if (bEn_i == 1'b1 && bWr_i[wr_bit] == 1'b1)
            block[bAddr_i][wr_bit] <= bDataIn_i[wr_bit];
    end
end
endgenerate

logic [W:0] bOutBuf [DELAY];
generate
for (rd_bit=0; rd_bit<WIDTH; rd_bit=rd_bit+1) begin: block_bread
    always @(posedge bClk_i) begin
        if(bEn_i == 1'b1) begin
            if(bWr_i[rd_bit] == 1'b0)
                bOutBuf[DELAY-1][rd_bit] <= block[bAddr_i][rd_bit];
            else
                bOutBuf[DELAY-1][rd_bit] <= bDataIn_i[rd_bit];
        end
    end
end
endgenerate

for(genvar i = 0; i < DELAY-1; i++)
    always @(posedge bClk_i) bOutBuf[i] <= bOutBuf[i+1];

assign bDataOut_o = bOutBuf[0];

/*task readHexFile(string fname, int offset);
    $readmemh(fname, offset);
endtask*/

endmodule