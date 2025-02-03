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

// https://zipcpu.com/blog/2020/08/22/oddr.html

`default_nettype none

module SerializerDDR (
    input  wire logic       clk_i,
    input  wire logic [1:0] data_i,
    input  wire logic       bypass_i, //when set, data_i[0] appears at data_o as if passed through simple ff
    output wire logic       data_o
);

// input --> demultiplex -+--> buf_p --------------> XOR --> out
//             |          |                          |
//             + ----- <--+--> buf_n ---> buf_nn --> +
//                                       (negedge)

logic buf_p;    //positive edge buffer
logic buf_n;    //negative edge buffer
logic buf_nn;   //negative edge buffer, on negative edge

always_ff @( posedge clk_i ) begin : demux
    buf_p <= data_i[1] ^ buf_n;
    buf_n <= bypass_i ? 1'b0 : data_i[0] ^ data_i[1] ^ buf_n;
end

always_ff @( negedge clk_i ) buf_nn <= buf_n;

assign data_o = buf_p ^ buf_nn;

endmodule