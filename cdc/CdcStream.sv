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

module CdcStream #(
    parameter WIDTH = 16
) (
    input   wire logic              srcClk_i,
    input   wire logic              srcRst_i,
    input   wire logic[WIDTH-1:0]   srcData_i,
    input   wire logic              srcValid_i,
    output  wire logic              srcStall_o,

    input   wire logic              dstClk_i,
    input   wire logic              dstRst_i,
    output  wire logic[WIDTH-1:0]   dstData_o,
    output  wire logic              dstValid_o,
    input   wire logic              dstStall_i
);

localparam W = WIDTH-1;

logic srcActive;
logic dstActive;

//position loop

//                             : clock boundary
//                             :
//         +->-------->- WPos ->- CDC0 ->- CDC1 ->-+->- WPos
//         |                   :                   |
// RPos -<-+-<- CDC1 -<- CDC0 -<- RPos -<--------<-+
//                             :
//                             :

// WPos
//write pos CDC pipeline
// WPos -> greyEnc -> CDC -> greyDec -> dstWPos (->- RPosNext)
logic [2:0] srcWritePos, srcWritePosGrey, dstWritePosGrey, dstWritePos;
logic [2:0] srcWritePosPlusOne;
always_ff @( posedge srcClk_i, posedge srcRst_i ) begin
    if(srcRst_i == 1'b1)        srcWritePos <= 'd0;
    else if(srcActive == 1'b1)  srcWritePos <= srcWritePosPlusOne;
    else                        srcWritePos <= srcWritePos;
end
assign srcWritePosPlusOne =
    srcWritePos == 3'd5 ? 3'd0 : srcWritePos + 1;

GreyEncode #(3) writePosSrcEnc(
    .raw_i          (srcWritePos),
    .enc_o          (srcWritePosGrey)
);

CdcBuffer #(3) writePos (
    .srcIn_i        (srcWritePosGrey),
    .dstClk_i       (dstClk_i),
    .dstRst_i       (dstRst_i),
    .dstOut_o       (dstWritePosGrey)
);

GreyDecode #(3) writePosDstDec (
    .enc_i          (dstWritePosGrey),
    .raw_o          (dstWritePos)
);

//read pos CDC pipeline
// RPos -> greyEnc -> CDC -> greyDec -> srcRPos (->- WPosNext)
logic [2:0] dstReadPos, dstReadPosGrey, srcReadPosGrey, srcReadPos;
logic [2:0] dstReadPosPlusOne;
always_ff @( posedge dstClk_i, posedge dstRst_i ) begin
    if(dstRst_i == 1'b1)        dstReadPos <= 'd0;
    else if(dstActive == 1'b1)  dstReadPos <= dstReadPosPlusOne;
    else                        dstReadPos <= dstReadPos;
end
assign dstReadPosPlusOne =
    dstReadPos == 3'd5 ? 3'd0 : dstReadPos + 1;


GreyEncode #(3) readPosDstEnc(
    .raw_i          (dstReadPos),
    .enc_o          (dstReadPosGrey)
);

CdcBuffer #(3) readPos (
    .srcIn_i        (dstReadPosGrey),
    .dstClk_i       (srcClk_i),
    .dstRst_i       (srcRst_i),
    .dstOut_o       (srcReadPosGrey)
);

GreyDecode #(3) readPosDstDec (
    .enc_i          (srcReadPosGrey),
    .raw_o          (srcReadPos)
);

// data pipelines

// in ->- mux ->- srcBuf0 ->- dstBuf0 ->- mux ->- out
//          |                             |
//          +-->- srcBuf1 ->- dstBuf1 ->--+
//          |                             |
//          ...                         ...

// output of dstBufX may be metastable - but will only be used when the pos
// buffer are synchronized.

//mux
logic [W:0] srcBuffer[6];
logic [W:0] dstBuffer[6];
always_ff @( posedge srcClk_i ) begin
    srcBuffer[0] <= srcActive == 1'b1 && srcWritePos == 'd0 ? srcData_i : srcBuffer[0];
    srcBuffer[1] <= srcActive == 1'b1 && srcWritePos == 'd1 ? srcData_i : srcBuffer[1];
    srcBuffer[2] <= srcActive == 1'b1 && srcWritePos == 'd2 ? srcData_i : srcBuffer[2];
    srcBuffer[3] <= srcActive == 1'b1 && srcWritePos == 'd3 ? srcData_i : srcBuffer[3];
    srcBuffer[4] <= srcActive == 1'b1 && srcWritePos == 'd4 ? srcData_i : srcBuffer[4];
    srcBuffer[5] <= srcActive == 1'b1 && srcWritePos == 'd5 ? srcData_i : srcBuffer[5];
end

// srcBuf -> dstBuf
always_ff @( posedge dstClk_i ) begin
    dstBuffer[0] <= srcBuffer[0];
    dstBuffer[1] <= srcBuffer[1];
    dstBuffer[2] <= srcBuffer[2];
    dstBuffer[3] <= srcBuffer[3];
    dstBuffer[4] <= srcBuffer[4];
    dstBuffer[5] <= srcBuffer[5];
end

// mux
assign dstData_o =
    dstReadPos == 'd0 ? dstBuffer[0]:
    dstReadPos == 'd1 ? dstBuffer[1]:
    dstReadPos == 'd2 ? dstBuffer[2]:
    dstReadPos == 'd3 ? dstBuffer[3]:
    dstReadPos == 'd4 ? dstBuffer[4]:
                        dstBuffer[5];

//control core
assign srcActive =
    srcRst_i == 1'b0
 && srcWritePosPlusOne != srcReadPos
 && srcValid_i == 1'b1
  ? 1'b1 : 1'b0;

assign dstActive =
    dstRst_i == 1'b0
 && dstReadPos != dstWritePos
 && dstStall_i == 1'b0
  ? 1'b1 : 1'b0;

//

assign srcStall_o = ~srcActive;
assign dstValid_o = dstActive;

endmodule

