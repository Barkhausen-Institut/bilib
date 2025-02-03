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

module BiMemConvert #(
    parameter USE_DATA_SIZE = 16,
    parameter USE_ADDR_SIZE = 4,
    parameter USE_MASK_SIZE = 4,
    parameter MEM_DATA_SIZE = 32,
    parameter MEM_ADDR_SIZE = 8,
    parameter MEM_MASK_SIZE = 8
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,

    input   wire logic                      useEnable_i,
    input   wire logic                      useIsWrite_i,
    input   wire logic[USE_MASK_SIZE-1:0]   useWriteMask_i,
    input   wire logic[USE_ADDR_SIZE-1:0]   useAddr_i,
    input   wire logic[USE_DATA_SIZE-1:0]   useWriteData_i,
    output  wire logic[USE_DATA_SIZE-1:0]   useReadData_o,
    output  wire logic                      useHold_o,
   
    output  wire logic                      memEnable_o,
    output  wire logic                      memIsWrite_o,
    output  wire logic[MEM_MASK_SIZE-1:0]   memWriteMask_o,
    output  wire logic[MEM_ADDR_SIZE-1:0]   memAddr_o,
    output  wire logic[MEM_DATA_SIZE-1:0]   memWriteData_o,
    input   wire logic[MEM_DATA_SIZE-1:0]   memReadData_i,
    input   wire logic                      memHold_i
);

//shrink means that the mem interface has a smaller data size than the use interface
localparam SHRINK = USE_DATA_SIZE > MEM_DATA_SIZE;
//multiplier to get from useAddr  to memAddr (only for growing interface)
localparam MULT = MEM_DATA_SIZE / USE_DATA_SIZE;
localparam BITS = $clog2(MULT);
//bits represented by one writeMask bit
localparam USE_CHUNK = USE_DATA_SIZE / USE_MASK_SIZE;
localparam MEM_CHUNK = MEM_DATA_SIZE / MEM_MASK_SIZE;

`ifdef SIMULATION
    initial begin
        //only growing interface is supported
        assert(SHRINK == 0) else
            $fatal("mem converter only works for growing interface");
        //check if the sizes are compatible
        assert(MEM_DATA_SIZE % USE_DATA_SIZE == 0) else
            $fatal("MEM_DATA_SIZE must be a multiple of USE_DATA_SIZE"); 
        assert(USE_DATA_SIZE % MEM_DATA_SIZE == 0) else
            $fatal("USE_DATA_SIZE must be a multiple of MEM_DATA_SIZE");
        //check that no rest chunk is there
        assert(USE_DATA_SIZE % USE_MASK_SIZE == 0) else
            $fatal("WriteMask must spilt data in even chunks");
        assert(MEM_DATA_SIZE % MEM_MASK_SIZE == 0) else
            $fatal("WriteMask must spilt data in even chunks");
        //check that chunk sizes are compatible
        assert(USE_CHUNK == MEM_CHUNK) else
            $fatal("Chunk sizes must be compatible");
        //check that MULT is a power of two
        assert(2**BITS == MULT) else
            $fatal("data size factor must be power of two")
        //address sizes must be same
        assert(USE_ADDR_SIZE == MEM_ADDR_SIZE) else
            $fatal("address size must be equal")
    end
`endif

//growing interface
assign memEnable_o = useEnable_i;
assign memIsWrite_o = useIsWrite_i;
assign memAddr_o = {{BITS{1'b0}}, useAddr_i[USE_ADDR_SIZE-1:BITS]};

genvar i;
for(i = 0; i < MULT; i++) begin : dataSel
    assign memWriteMask_o[i*USE_MASK_SIZE+:USE_MASK_SIZE] =
        i == useAddr_i[BITS-1:0] ? useWriteMask_i : '0;
    assign memWriteData_o[i*USE_DATA_SIZE+:USE_DATA_SIZE] =
        i == useAddr_i[BITS-1:0] ? useWriteData_i : '0;
end

logic [BITS-1:0] bsel_r;
always_ff @(posedge clk_i) bsel_r <= useAddr_i[BITS-1:0];

assign useReadData_o = memReadData_i[bsel_r*USE_DATA_SIZE+:USE_DATA_SIZE];
assign useHold_o = memHold_i;

endmodule