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
logic clk2;
assign clk2 = clk_i;
logic rst2;
assign rst2 = rst_i;


//buffer
logic bufIn;
logic bufOut;
CdcBuffer cdcBuf (
    .srcIn_i        (bufIn),
    .dstClk_i       (clk),
    .dstRst_i       (rst),
    .dstOut_o       (bufOut)
);

SiCoPlayer #(
    .CHANNEL        ("bufIn"),
    .WIDTH          (1)
) bufInPly (
    .val_o          (bufIn)
);

SiCoRecorder #(
    .CHANNEL        ("bufOut"),
    .WIDTH          (1)
) bufOutRec (
    .val_i          (bufOut)
);

//mutex
logic mtxLLocked;
logic mtxLRelease;
logic mtxRLocked;
logic mtxRRelease;
CdcMutex mtx (
    .srcClk_i       (clk),
    .srcRst_i       (rst),
    .srcRelease_i   (mtxLRelease),
    .srcLocked_o    (mtxLLocked),
    .dstClk_i       (clk2),
    .dstRst_i       (rst2),
    .dstRelease_i   (mtxRRelease),
    .dstLocked_o    (mtxRLocked)
);

SiCoClkdPlayer #(
    .CHANNEL        ("mtxLRelease"),
    .WIDTH          (1)
) mtxLReleasePly (
    .clk_i          (clk),
    .val_o          (mtxLRelease)
);

SiCoClkdRecorder #(
    .CHANNEL        ("mtxLLocked"),
    .WIDTH          (1)
) mtxLLockedRec (
    .clk_i          (clk),
    .val_i          (mtxLLocked)
);

SiCoClkdPlayer #(
    .CHANNEL        ("mtxRRelease"),
    .WIDTH          (1)
) mtxRReleasePly (
    .clk_i          (clk),
    .val_o          (mtxRRelease)
);

SiCoClkdRecorder #(
    .CHANNEL        ("mtxRLocked"),
    .WIDTH          (1)
) mtxRLockedRec (
    .clk_i          (clk),
    .val_i          (mtxRLocked)
);

//event
logic evtRequest;
logic evtReady;
logic evtEvent;
CdcEvent evt (
    .srcClk_i       (clk),
    .srcRst_i       (rst),
    .srcRequest_i   (evtRequest),
    .srcReady_o     (evtReady),
    .dstClk_i       (clk2),
    .dstRst_i       (rst2),
    .dstEvent_o     (evtEvent)
);

SiCoClkdPlayer #(
    .CHANNEL        ("evtRequest"),
    .WIDTH          (1)
) evtRequestPly (
    .clk_i          (clk),
    .val_o          (evtRequest)
);

SiCoClkdRecorder #(
    .CHANNEL        ("evtReady"),
    .WIDTH          (1)
) evtReadyRec (
    .clk_i          (clk),
    .val_i          (evtReady)
);

SiCoClkdRecorder #(
    .CHANNEL        ("evtEvent"),
    .WIDTH          (1)
) evtEventRec (
    .clk_i          (clk),
    .val_i          (evtEvent)
);

//gate
logic       gteWrite;
logic [7:0] gteIn;
logic       gteWOpen;
logic       gteRead;
logic [7:0] gteOut;
logic       gteROpen;
CdcGate gte (
    .srcClk_i       (clk),
    .srcRst_i       (rst),
    .srcWrite_i     (gteWrite),
    .srcData_i      (gteIn),
    .srcOpen_o      (gteWOpen),
    .dstClk_i       (clk2),
    .dstRst_i       (rst2),
    .dstRead_i      (gteRead),
    .dstData_o      (gteOut),
    .dstOpen_o      (gteROpen)
);

SiCoClkdPlayer #(
    .CHANNEL        ("gteWrite"),
    .WIDTH          (1)
) gteWritePly (
    .clk_i          (clk),
    .val_o          (gteWrite)
);

SiCoClkdPlayer #(
    .CHANNEL        ("gteIn"),
    .WIDTH          (8)
) gteInPly (
    .clk_i          (clk),
    .val_o          (gteIn)
);

SiCoClkdRecorder #(
    .CHANNEL        ("gteWOpen"),
    .WIDTH          (1)
) gteWOpenRec (
    .clk_i          (clk),
    .val_i          (gteWOpen)
);

SiCoClkdPlayer #(
    .CHANNEL        ("gteRead"),
    .WIDTH          (1)
) gteReadPly (
    .clk_i          (clk),
    .val_o          (gteRead)
);

SiCoClkdRecorder #(
    .CHANNEL        ("gteOut"),
    .WIDTH          (8)
) gteOutRec (
    .clk_i          (clk),
    .val_i          (gteOut)
);

SiCoClkdRecorder #(
    .CHANNEL        ("gteROpen"),
    .WIDTH          (1)
) gteROpenRec (
    .clk_i          (clk),
    .val_i          (gteROpen)
);

//gate
logic       stmInValid;
logic [7:0] stmIn;
logic       stmInStall;
logic       stmOutValid;
logic [7:0] stmOut;
logic       stmOutStall;
CdcStream stm (
    .srcClk_i       (clk),
    .srcRst_i       (rst),
    .srcValid_i     (stmInValid),
    .srcData_i      (stmIn),
    .srcStall_o     (stmInStall),
    .dstClk_i       (clk2),
    .dstRst_i       (rst2),
    .dstStall_i     (stmOutStall),
    .dstData_o      (stmOut),
    .dstValid_o     (stmOutValid)
);

SiCoClkdPlayer #(
    .CHANNEL        ("stmInValid"),
    .WIDTH          (1)
) stmInValidPly (
    .clk_i          (clk),
    .val_o          (stmInValid)
);

SiCoClkdPlayer #(
    .CHANNEL        ("stmIn"),
    .WIDTH          (8)
) stmInPly (
    .clk_i          (clk),
    .val_o          (stmIn)
);

SiCoClkdRecorder #(
    .CHANNEL        ("stmInStall"),
    .WIDTH          (1)
) stmInStallRec (
    .clk_i          (clk),
    .val_i          (stmInStall)
);

SiCoClkdPlayer #(
    .CHANNEL        ("stmOutStall"),
    .WIDTH          (1)
) stmOutStallPly (
    .clk_i          (clk),
    .val_o          (stmOutStall)
);

SiCoClkdRecorder #(
    .CHANNEL        ("stmOut"),
    .WIDTH          (8)
) stmOutRec (
    .clk_i          (clk),
    .val_i          (stmOut)
);

SiCoClkdRecorder #(
    .CHANNEL        ("stmOutValid"),
    .WIDTH          (1)
) stmOutValidRec (
    .clk_i          (clk),
    .val_i          (stmOutValid)
);

endmodule