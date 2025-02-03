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

module SimpleBench (
    input wire logic        clk_i,
    input wire logic        rst_i
);

//clocking
logic clk;
assign clk = clk_i;
logic rst;
assign rst = rst_i;

//encode
_8b10bTypes::symbol     encIn;
logic                   encInDisparity;
_8b10bTypes::symbol10   encOut;
logic                   encOutDisparity;
_8b10bEncode enc (
    .raw_i      (encIn),
    .RD_i       (encInDisparity),
    .encoded_o  (encOut),
    .RDNext_o   (encOutDisparity)
);

SiCoPlayer #(
    .CHANNEL        ("encIn"),
    .WIDTH          (_8b10bTypes::SYMBOL_WIDTH)
) encInPly (
    .val_o          (encIn)
);

SiCoPlayer #(
    .CHANNEL        ("encInDisp"),
    .WIDTH          (1)
) encInDispPly (
    .val_o          (encInDisparity)
);

SiCoRecorder #(
    .CHANNEL        ("encOut"),
    .WIDTH          (_8b10bTypes::SYMBOL10_WIDTH)
) encOutRec (
    .val_i          (encOut)
);

SiCoRecorder #(
    .CHANNEL        ("encOutDisp"),
    .WIDTH          (1)
) encOutDispRec (
    .val_i          (encOutDisparity)
);

//decode

_8b10bTypes::symbol10   decIn;
_8b10bTypes::symbol     decOut;
_8b10bDecode dec (
    .encoded_i      (decIn),
    .raw_o          (decOut)
);

SiCoPlayer #(
    .CHANNEL        ("decIn"),
    .WIDTH          (_8b10bTypes::SYMBOL10_WIDTH)
)  decInPly (
    .val_o          (decIn)
);

SiCoRecorder #(
    .CHANNEL        ("decOut"),
    .WIDTH          (_8b10bTypes::SYMBOL_WIDTH)
)  decOutRec (
    .val_i          (decOut)
);


endmodule