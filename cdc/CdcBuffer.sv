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
// Clock Domain Crossing
//   Signal Buffer
//
// Simple clock domain crossing by two flipflop chain.

`default_nettype none
module CdcBuffer #(
    parameter WIDTH = 1
) (
    input   wire logic[WIDTH-1:0]   srcIn_i,

    input   wire logic              dstClk_i,
    input   wire logic              dstRst_i,
    output  wire logic[WIDTH-1:0]   dstOut_o
);

`ifdef XILINX_FPGA

    (* ASYNC_REG = "TRUE", KEEP = "TRUE" *)
    logic [WIDTH-1:0] dstPipe, xxxPipe;
    always @(posedge dstClk_i or posedge dstRst_i) begin
        if(dstRst_i == 1'b1)    {dstPipe, xxxPipe} <= '0;
        else                    {dstPipe, xxxPipe} <= {xxxPipe, srcIn_i};
    end
    assign dstOut_o = dstPipe;

`elsif RACYICS

    genvar gen_i;
    generate
        for(gen_i=0; gen_i<WIDTH; gen_i=gen_i+1) begin: SYNC_GEN
            ri_common_sync i_common_sync (
                .clk_i     (dstClk_i),
                .reset_n_i (~dstRst_i),
                .data_i    (srcIn_i[gen_i]),
                .data_o    (dstOut_o[gen_i])
            );
        end
    endgenerate

`else

    logic [WIDTH-1:0] dstPipe, xxxPipe;
    always @(posedge dstClk_i or posedge dstRst_i) begin
        if(dstRst_i == 1'b1)    {dstPipe, xxxPipe} <= '0;
        else                    {dstPipe, xxxPipe} <= {xxxPipe, srcIn_i};
    end
    assign dstOut_o = dstPipe;
    
`endif



endmodule