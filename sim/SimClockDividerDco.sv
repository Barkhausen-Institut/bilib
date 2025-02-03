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

// SimClockDividerDco
//
//   takes a clock and divides it into DIVIDER clocks that are shifted to
//   each other
//   The clock are DIVIDER times slower than the input clock
//   The clock's edges are equaly spaced around the whole cycle

// Example: DIVIDER = 8
// r -_-_-_-_-_-_-_-_   clk_i
// 7 --------________
// 6 __--------______
// 5 ____--------____
// 4 ______--------__
// 3 ________--------
// 2 --________------
// 1 ----________----
// 0 ------________--


module SimClockDividerDco #(
    parameter DIVIDER = 2
) (
    input   wire logic                  clk_i,
    output  wire logic [DIVIDER-1:0]    clk_o
);

localparam DIVIDER_LENGTH = $clog2(DIVIDER);

logic[DIVIDER_LENGTH-1:0]   counter;
logic[DIVIDER-1:0]          clk;

initial begin
    int n;
    counter = 0;
    forever begin
        @( posedge clk_i );
        if(counter == DIVIDER - 1)  counter = '0;
        else                        counter = counter + 1;
        for(n = 0; n < DIVIDER; n++) begin
            if(counter == n)                                clk[DIVIDER-1-n] = 1'b1;
            else if(counter == (n + DIVIDER/2) % DIVIDER)   clk[DIVIDER-1-n] = 1'b0;
        end
    end
end

genvar i;
generate
    for(i = 0; i < DIVIDER; i++) begin : bits
        ClockBuffer clkBuf (
            .in_i               (clk[i]),
            .out_o              (clk_o[i])
        );
    end
endgenerate

endmodule