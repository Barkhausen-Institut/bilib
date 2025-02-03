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

package SiCoDpi;

import "DPI-C" task  SiCoDpiPlayerGet32(
    input   string      chan,
    input   longint     now,
    output  logic[31:0] data,
    output  logic       sync,
    output  longint     deadline
);

import "DPI-C" task  SiCoDpiPlayerGet128(
    input   string      chan,
    input   longint     now,
    output  logic[127:0]data,
    output  logic       sync,
    output  longint     deadline
);

import "DPI-C" task  SiCoDpiPlayerGet1024(
    input   string      chan,
    input   longint     now,
    output  logic[1024:0]data,
    output  logic       sync,
    output  longint     deadline
);

import "DPI-C" task  SiCoDpiPlayerGetNext32(
    input   string      chan,
    input   longint     now,
    output  logic[31:0] data,
    output  logic       valid
);

import "DPI-C" task  SiCoDpiPlayerGetNext128(
    input   string      chan,
    input   longint     now,
    output  logic[127:0]data,
    output  logic       valid
);

import "DPI-C" task  SiCoDpiPlayerGetNext1024(
    input   string      chan,
    input   longint     now,
    output  logic[1024:0]data,
    output  logic       valid
);

import "DPI-C" task  SiCoDpiRecorderPut32(
    input   string      chan,
    input   longint     now,
    input   logic[31:0] data,
    input   int         size,
    input   int         flags   //0:sync 1:force
);

import "DPI-C" task  SiCoDpiRecorderPut128(
    input   string      chan,
    input   longint     now,
    input   logic[127:0]data,
    input   int         size,
    input   int         flags   //0:sync 1:force
);

import "DPI-C" task  SiCoDpiRecorderPut1024(
    input   string      chan,
    input   longint     now,
    input   logic[1023:0]data,
    input   int         size,
    input   int         flags   //0:sync 1:force
);

import "DPI-C" task SiCoDpiPlayerInit32(
    input   string      chan,
    input   logic[31:0] reset,
    input   int         size,
    input   int         flags   //0:sync 1:clocked
);

import "DPI-C" task SiCoDpiPlayerInit128(
    input   string      chan,
    input   logic[127:0]reset,
    input   int         size,
    input   int         flags   //0:sync 1:clocked
);

import "DPI-C" task SiCoDpiPlayerInit1024(
    input   string      chan,
    input   logic[1024:0]reset,
    input   int         size,
    input   int         flags   //0:sync 1:clocked
);

import "DPI-C" task SiCoDpiRecorderInit32(
    input   string      chan,
    input   logic[31:0] reset,
    input   int         size,
    input   int         flags   //1:clocked
);

import "DPI-C" task SiCoDpiRecorderInit128(
    input   string      chan,
    input   logic[127:0]reset,
    input   int         size,
    input   int         flags   //1:clocked
);

import "DPI-C" task SiCoDpiRecorderInit1024(
    input   string      chan,
    input   logic[1024:0]reset,
    input   int         size,
    input   int         flags   //1:clocked
);

import "DPI-C" task SiCoDpiSetup();

import "DPI-C" task SiCoDpiTick(input longint now);
task tick(input longint now);
    SiCoDpiTick(now);
endtask

import "DPI-C" task SiCoDpiConfigInt64(input string name, input longint val);
import "DPI-C" task SiCoDpiConfigStrStr(input string name, input string val1, input string val2);

export "DPI-C" task SiCoDpiFinish;
task SiCoDpiFinish();
    $finish;
endtask

export "DPI-C" task SiCoDpiStop;
task SiCoDpiStop();
    $stop;
endtask

endpackage