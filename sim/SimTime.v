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

`timescale 1ps/1ps
`default_nettype none

module SimTime;

function automatic signed[63:0] now;
    input reg i;
    now = $time;
endfunction

task waitTime(input signed[63:0] amount);
    #(amount);
endtask

endmodule
