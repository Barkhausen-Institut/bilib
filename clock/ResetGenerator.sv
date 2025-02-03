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
module ResetGenerator #(
    parameter LENGTH = 16
)(
    input   wire    sysClk_i,
    input   wire    sysRst_i,
    input   wire    genClk_i,
    output  wire    genRst_o,
    input   wire    done_i
);

localparam W = $clog2(LENGTH);

logic [W-1:0] counter;

always_ff @(posedge sysClk_i, posedge sysRst_i) begin
    if(sysRst_i == 1'b1)        counter <= '1;
    else if(done_i == 1'b0)     counter <= '1;
    else if(counter != '0)      counter <= counter - 1;
    else                        counter <= counter;
end

logic grub;
assign grub = counter != '0 ? 1'b1 : 1'b0;

logic grub_r;
always_ff @(posedge sysClk_i) grub_r <= grub;

ResetSync sync (
    .clk_i          (genClk_i),
    .rst_i          (grub_r),
    .rst_o          (genRst_o)
);

endmodule 
