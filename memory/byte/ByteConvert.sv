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

module ByteConvert #(
    parameter USE_DATA_BYTE = 4,
    parameter USE_ADDR_SIZE = 32,
    parameter MEM_DATA_BYTE = 8,
    parameter MEM_ADDR_SIZE = 32
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,

    input   wire logic                      useEnable_i,
    input   wire logic                      useIsWrite_i,
    input   wire logic[USE_DATA_BYTE-1:0]   useWriteMask_i,
    input   wire logic[USE_ADDR_SIZE-1:0]   useAddr_i,
    input   wire logic[USE_DATA_BYTE*8-1:0] useWriteData_i,
    output  wire logic[USE_DATA_BYTE*8-1:0] useReadData_o,
    output  wire logic                      useHold_o,
   
    output  wire logic                      memEnable_o,
    output  wire logic                      memIsWrite_o,
    output  wire logic[MEM_DATA_BYTE-1:0]   memWriteMask_o,
    output  wire logic[MEM_ADDR_SIZE-1:0]   memAddr_o,
    output  wire logic[MEM_DATA_BYTE*8-1:0] memWriteData_o,
    input   wire logic[MEM_DATA_BYTE*8-1:0] memReadData_i,
    input   wire logic                      memHold_i

);

`ifndef SYNTHESIS
initial begin
    //address sizes must be same
    assert(USE_ADDR_SIZE == MEM_ADDR_SIZE) else
        $fatal(1, "address size must be equal");
end
`endif

//highest bit that does not change the memory line
localparam USE_LOW_BIT = $clog2(USE_DATA_BYTE);
localparam MEM_LOW_BIT = $clog2(MEM_DATA_BYTE);

////
//pass through 
if(USE_DATA_BYTE == MEM_DATA_BYTE) begin : pass_through

    assign  memEnable_o = useEnable_i;
    assign  memIsWrite_o = useIsWrite_i;
    assign  memWriteMask_o = useWriteMask_i;
    assign  memAddr_o = useAddr_i;
    assign  memWriteData_o = useWriteData_i;
    assign  useReadData_o = memReadData_i;
    assign  useHold_o = memHold_i;

end

////
//growing interface
else if(USE_DATA_BYTE < MEM_DATA_BYTE) begin : growing_if

    localparam BLOCKS = MEM_DATA_BYTE / USE_DATA_BYTE;

    `ifdef SIMULATION
        initial begin
            //check that BYTES are power of two
            assert(2**USE_LOW_BIT == USE_DATA_BYTE) else
                $fatal(1, "data size must be power of two");
            assert(2**MEM_LOW_BIT == MEM_DATA_BYTE) else
                $fatal(1, "data size must be power of two");
        end
    `endif

    assign memEnable_o = useEnable_i;
    assign memIsWrite_o = useIsWrite_i;
    assign memAddr_o = {useAddr_i[USE_ADDR_SIZE-1:MEM_LOW_BIT], {MEM_LOW_BIT{1'b0}}}; 

    logic [MEM_LOW_BIT-USE_LOW_BIT-1:0] bsel, bsel_r;
    assign bsel = useAddr_i[MEM_LOW_BIT-1:USE_LOW_BIT];
    always_ff @(posedge clk_i) bsel_r <= bsel;

    genvar i;
    for(i = 0; i < BLOCKS; i++) begin : dataSel
        assign memWriteMask_o[i*USE_DATA_BYTE+:USE_DATA_BYTE] =
            i == bsel ? useWriteMask_i : '0;
        assign memWriteData_o[i*USE_DATA_BYTE*8+:USE_DATA_BYTE*8] =
            i == bsel ? useWriteData_i : '0;
    end

    assign useReadData_o = memReadData_i[bsel_r*USE_DATA_BYTE*8+:USE_DATA_BYTE*8];
    assign useHold_o = memHold_i;
end

////
//shrinking interface
else begin : shrinking_if //USE_DATA_BYTE > MEM_DATA_BYTE

    //shrink is the multiplier how many data words of 'Mem' fit 'Use'
    localparam SHRINK = USE_DATA_BYTE / MEM_DATA_BYTE;

    logic memReading_r; 
    logic memReading; //read request and not hold
    logic memWriting; //write request and not hold
    logic memAccess;  //reading or writing

    //shift buffer
    reg  [MEM_DATA_BYTE*8-1:0]  shiftBuf[SHRINK-1];
    logic                       shiftBufRead;   //shifting in a new read value
    genvar i;
    always @(posedge clk_i)  shiftBuf[0] <= shiftBufRead ? memReadData_i : shiftBuf[0];
    for(i = 1; i < SHRINK-1; i++) begin
        always @(posedge clk_i) shiftBuf[i] <= shiftBufRead ? shiftBuf[i-1] : shiftBuf[i];
    end
    assign shiftBufRead = memReading_r;


    //read data assembly
    logic [USE_DATA_BYTE*8-1:0] readData;       //assembled data 
    assign readData[MEM_DATA_BYTE*8*(SHRINK-1)+:MEM_DATA_BYTE*8] = memReadData_i;
    for(i = 0; i < SHRINK-1; i++) begin
        assign readData[i*MEM_DATA_BYTE*8+:MEM_DATA_BYTE*8] = shiftBuf[SHRINK-2-i];
    end

    //write data selection
    logic [MEM_DATA_BYTE*8-1:0] writeData;
    logic [MEM_DATA_BYTE-1:0]   writeMask;
    logic [$clog2(SHRINK):0]    serCounter;
    assign writeData = useWriteData_i[serCounter*MEM_DATA_BYTE*8+:MEM_DATA_BYTE*8];
    assign writeMask = useWriteMask_i[serCounter*MEM_DATA_BYTE+:MEM_DATA_BYTE];

    //serializer block counter
    logic [MEM_ADDR_SIZE-1:0]   serAddr;
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i)                       serCounter <= '0;
        else if(memReading || memWriting) begin
            if(serCounter == SHRINK-1)  serCounter <= '0;          //request done
            else                        serCounter <= serCounter + 1; //next block 
        end else                        serCounter <= serCounter;     //wait
    end
    assign serAddr = {useAddr_i[USE_ADDR_SIZE-1:USE_LOW_BIT], {USE_LOW_BIT{1'b0}}} + (serCounter * MEM_DATA_BYTE);

    //memory interface
    assign memEnable_o = useEnable_i;
    assign memIsWrite_o = useIsWrite_i;
    assign memAddr_o = serAddr;
    assign memWriteData_o = memWriting ? writeData : '0;
    assign memWriteMask_o = memWriting ? writeMask : '0;
    assign memReading = memEnable_o & ~memIsWrite_o & ~memHold_i;
    assign memWriting = memEnable_o & memIsWrite_o & ~memHold_i;
    assign memAccess = memReading | memWriting;
    always @(posedge clk_i) memReading_r <= memReading;

    //use memory interface
    assign useReadData_o = serCounter == 0 && memReading_r ? readData : '0;
    assign useHold_o = (useEnable_i && (~memAccess || serCounter != SHRINK-1)) ? 1'b1 : 1'b0;


    //PanicModule pm();

end

endmodule