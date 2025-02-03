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

package BiSet;

parameter BISET_ADDRLEN = 8;
parameter BISET_CTRLLEN = BISET_ADDRLEN + 1;
parameter BISET_DATALEN = 32;
parameter BISET_REPLYLEN = BISET_DATALEN + 1;

typedef logic[BISET_ADDRLEN-1:0]    biSetAddr;
typedef logic[BISET_CTRLLEN-1:0]    biSetCtrl;  //{writeEnable, Addr}
typedef logic[BISET_DATALEN-1:0]    biSetData;
typedef logic[BISET_REPLYLEN-1:0]   biSetReply; //{valid, Data}

function biSetCtrl BiSetCtrl(input logic writeEnable, input biSetAddr addr);
    BiSetCtrl = {writeEnable, addr};
endfunction

function logic BiSetReplyValid(input biSetReply val);
    BiSetReplyValid = val[BISET_REPLYLEN-1];
endfunction

function biSetAddr BiSetCtrlAddr(input biSetCtrl val);
    BiSetCtrlAddr = val[BISET_ADDRLEN-1:0];
endfunction

function logic BiSetCtrlWriteEnable(input biSetCtrl val);
    BiSetCtrlWriteEnable = val[BISET_CTRLLEN-1];
endfunction

function logic BiSetCtrlEnable(input biSetCtrl val);
    BiSetCtrlEnable = |val;
endfunction

function biSetReply BiSetDataReply(input biSetData val);
    BiSetDataReply = {1'b1, val};
endfunction

function biSetData BiSetReplyData(input biSetReply val);
    BiSetReplyData = val[BISET_DATALEN-1:0];
endfunction



endpackage