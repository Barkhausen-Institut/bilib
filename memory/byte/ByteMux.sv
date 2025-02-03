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

// REG_ARBITER decides if the arbiter decision is registered.
//   that means that the hold signals are not combinatorical dependent on the enable signals
//   if the requesting user is already arbitrated the request can be handled
//   otherwise it will always take one cycle before access is granted


module ByteMux #(
    parameter USER = 2,
    parameter DATA_BYTE = 4,
    parameter ADDR_SIZE = 32,
    parameter ARBITRATION = "PRIO",
    parameter HOLDENABLE = 1, //if set to zero stalls are set even if enable ist not set
    parameter REG_ARBITER = 0, //if set aribter decision is saved in a register
    parameter BREAK_COMB_B = 0,
    parameter BREAK_COMB_C = 0,
    parameter ARBIT_FALLBACK = 1 //B input
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i, //only needed for REG_ARBITER

    input   wire logic                      useEnable_i     [USER],
    input   wire logic                      useIsWrite_i    [USER],
    input   wire logic[DATA_BYTE-1:0]       useWriteMask_i  [USER],
    input   wire logic[ADDR_SIZE-1:0]       useAddr_i       [USER],
    input   wire logic[DATA_BYTE*8-1:0]     useWriteData_i  [USER],
    output  wire logic[DATA_BYTE*8-1:0]     useReadData_o   [USER],
    output  wire logic                      useHold_o       [USER],
   
    output  wire logic                      memEnable_o,
    output  wire logic                      memIsWrite_o,
    output  wire logic[DATA_BYTE-1:0]       memWriteMask_o,
    output  wire logic[ADDR_SIZE-1:0]       memAddr_o,
    output  wire logic[DATA_BYTE*8-1:0]     memWriteData_o,
    input   wire logic[DATA_BYTE*8-1:0]     memReadData_i,
    input   wire logic                      memHold_i
);

typedef logic[$clog2(USER):0] arbit_t;

arbit_t arbit, arbit_r, arbit_next;

logic [2:0] arbit_timeout;
logic       arbit_active;   //any enable signal set

always_ff @(posedge clk_i or posedge rst_i) begin
    if(rst_i)                   arbit_timeout <= 0;
    else if(arbit_active)       arbit_timeout <= '1;
    else if(arbit_timeout != 0) arbit_timeout <= arbit_timeout - 1;
    else                        arbit_timeout <= '0;
end

//smaller use port indx, higher prio
always_comb begin
    arbit_next = arbit_r; //not neccessary - handled by arbit_timeout
    arbit_active = 1'b0;
    for(int i = 0; i < USER; i++) begin
        if(useEnable_i[USER-1-i]) begin
            arbit_next = USER - i;
            arbit_active = 1'b1;
        end
    end
end
if(REG_ARBITER == 1) begin
    always_ff @(posedge clk_i, posedge rst_i) begin
        if(rst_i)   arbit <= '0;
        else if(arbit_active)       arbit <= arbit_next;
        else if(arbit_timeout != 0) arbit <= arbit_r;
        else                        arbit <= ARBIT_FALLBACK;
    end
end else begin
    assign arbit = arbit_next;
end

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i)   arbit_r <= 1'b0;
    else        arbit_r <= arbit;
end

assign memEnable_o = arbit != 0 ? useEnable_i[arbit-1] : '0;
assign memIsWrite_o = arbit != 0 ? useIsWrite_i[arbit-1] : '0;
assign memWriteMask_o = arbit != 0 ? useWriteMask_i[arbit-1] : '0;
assign memAddr_o = arbit != 0 ? useAddr_i[arbit-1] : '0;
assign memWriteData_o = arbit != 0 ? useWriteData_i[arbit-1] : '0;


genvar i;
for(i = 0; i < USER; i++) begin
    if(HOLDENABLE)
        assign useHold_o[i] = useEnable_i[i] & (arbit == i+1 ? memHold_i : 1'b1);
    else
        assign useHold_o[i] = 
            arbit == 0 ?    1'b0 : 
            arbit == i+1 ?  (((BREAK_COMB_B && i == 1) || (BREAK_COMB_C && i == 2)) ? 1'b0 : memHold_i) :
                            1'b1 ;
    assign useReadData_o[i] = arbit_r == i+1 ? memReadData_i : '0;
end

endmodule