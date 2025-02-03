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

module Spit #(
    parameter TYPE = "no",
    parameter PROFILE = "spit",
    parameter integer WIDTH = 1,
    parameter integer HEIGHT = 1,
    parameter integer MASK = 1
) ();

    initial begin
        $display("SPIT w:%d h:%d m:%d t:%s p:%s m:%m", WIDTH, HEIGHT, MASK, TYPE, PROFILE);
    end
endmodule

