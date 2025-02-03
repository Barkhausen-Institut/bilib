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

module BiSetReplyMux # (
    parameter LENGTH = 2
) (
    input   wire BiSet::biSetReply  in_i[LENGTH],
    output  wire BiSet::biSetReply  out_o
);

BiSet::biSetReply out;


//icarus has a problem with non constant access of arrays
`ifdef NO_NON_CONSTANT_ARRAY_ACCESS

localparam S = 8;

BiSet::biSetReply cat [S];

genvar i;
for(i = 0; i < S; i++) begin : gencatter
    if(i < LENGTH)
        assign cat[i] = in_i[i];
    else
        assign cat[i] = '0;
end

initial begin
    assert (LENGTH <= 8) else $display("BiSetReplyMux cannot mux bigger than 8 signals - you can extend it very easily, however.") ;
end

assign out = 
    (cat[0] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[0])}})
  | (cat[1] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[1])}})
  | (cat[2] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[2])}})
  | (cat[3] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[3])}})
  | (cat[4] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[4])}})
  | (cat[5] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[5])}})
  | (cat[6] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[6])}})
  | (cat[7] & {BiSet::BISET_REPLYLEN{BiSet::BiSetReplyValid(cat[7])}});

`else

//more elegant solution, but icarus does not support it
always_comb begin : mux
    out = '0;
    for(int i = LENGTH-1; i >= 0; i--) begin
        if(BiSet::BiSetReplyValid(in_i[i]))
            out = in_i[i];
    end
end

`endif

assign out_o = out;

endmodule 