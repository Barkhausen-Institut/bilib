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

module _8b10bSerialize (
    input   wire logic          clk_i,
    input   wire logic          rst_i,
    input   wire _8b10b::pair10 parallel_i,
    input   wire logic          ddr_i,  //if set two bits are output each cycle
    output  wire logic          stall_o,
    output  wire logic [1:0]    serial_o//if ddr_i is false only [1] is valid
);

import _8b10b::*;

logic [19:0]    shiftreg;
logic [5:0]     counter;
logic           step;

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        shiftreg <= 'b10101010101010101010;
        counter <= 18;  //make the serializer do something after reset
        step <= 1'b0;
    end else if(~step) begin
        shiftreg <= shiftreg;
        counter <= counter;
        step <= 1'b1;
    end else if(counter == 0) begin
        shiftreg <= parallel_i;
        counter <= 18;
        step <= ddr_i;
    end else begin
        shiftreg <= {shiftreg[17:0], 2'b00};
        counter <= counter - 2;
        step <= ddr_i;
    end
end

assign stall_o = (counter == 0 && step) ? 1'b0 : 1'b1;

assign serial_o = (~step || ddr_i) ? shiftreg[19:18] : shiftreg[18:17];

endmodule