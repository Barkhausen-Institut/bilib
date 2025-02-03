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
`timescale 1ps/1ps

package SimHelper;

timeunit 1ps / 1ps;

localparam longint PSEC = 'd1;
localparam longint NSEC = 'd1_000; //pico seconds
localparam longint USEC = 'd1_000 * NSEC;
localparam longint MSEC = 'd1_000 * USEC;
localparam longint  HZ = 'd1;
localparam longint KHZ = 'd1_000 * HZ;
localparam longint MHZ = 'd1_000 * KHZ;
localparam longint GHZ = 'd1_000 * MHZ;
localparam longint E12 = 64'd1000000000000;

//convertion of cycle period to frequency (psec -> hz)
function automatic longint freq2Period(input longint freq);
    freq2Period = E12 / freq;
endfunction

//convertion of cycle period to frequency (hz -> psec)
function automatic longint period2Freq (input longint period);
    period2Freq = E12 / period;
endfunction

function automatic longint currTime ();
    $display("DEPRECATION WARNING: don't use currTime - use SimTime instead! (%m)");
    currTime = longint'($time);
endfunction

task waitTime(input longint amount);
    $display("DEPRECATION WARNING: don't use waitTime - use SimTime instead! (%m)");
    #(amount);
endtask

endpackage