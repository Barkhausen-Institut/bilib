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

////////////////////////////
//
// Pseudo Random Number Generator
//
// Produces a random number each cycle.
// Parameter BITS configures width of the random number. Cannot be > 32.

`default_nettype none

module PseudoRandomNumberGenerator #(
    BITS = 16
) (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    output  wire logic [BITS-1:0]   num_o
);
    
localparam RESETVAL = 'h14d5ba65;

logic   [32:0]  shift_next;
logic   [32:0]  shift_r;

always_ff @(posedge clk_i, posedge rst_i)
begin
    if(rst_i == 1'b1)   shift_r <= RESETVAL;
    else                shift_r <= shift_next;
end

assign shift_next =
    {shift_r[31:0], shift_r[32] ^ shift_r[13]};

assign num_o = shift_r[BITS-1:0];

endmodule