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

module DataRecover8 (
    input   wire logic              clk_i,
    input   wire logic              rst_i,
    input   wire logic              ddr_i,      //enable DDR mode
    input   wire logic[7:0]         data_i,
    output  wire logic[2:0]         data_o,     //bist become valid MSB->LSB
    output  wire logic[1:0]         valid_o     //number of valid bits
);

logic           shiftFast;      //decision to move the wave one to the left
logic           shiftSlow;      //descision to move the wave to the right
logic           shiftHold;      //decision to not output and jump pos from 0 to 7 or 0 to 3
logic           shiftDouble;    //descision to output two bits and jump pos from 7 to 0

logic           shiftFast_r;  
logic           shiftSlow_r;
logic           shiftHold_r;
logic           shiftDouble_r;
always_ff @(posedge clk_i) shiftFast_r <= shiftFast;
always_ff @(posedge clk_i) shiftSlow_r <= shiftSlow;
always_ff @(posedge clk_i) shiftHold_r <= shiftHold;
always_ff @(posedge clk_i) shiftDouble_r <= shiftDouble;

//wave position
logic [2:0]     pos;
always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i)                               pos <= 3;
    else if(ddr_i && shiftFast && pos == 3) pos <= 0;
    else if(ddr_i && shiftSlow && pos == 0) pos <= 3;
    else if(shiftFast)                      pos <= pos + 1;
    else if(shiftSlow)                      pos <= pos - 1;
    else                                    pos <= pos;
end


// 16:16        last bit from last frame
// 15: 8        current frame
//  7: 0        back buffer
logic [16:0]    data;
logic [16:0]    newData;
logic [16:0]    oldData;

//align new incoming data
always_comb begin : shifter
    case(pos)
    3'd0:   newData = {1'b0, data_i, 8'b0};
    3'd1:   newData = {2'b0, data_i, 7'b0};
    3'd2:   newData = {3'b0, data_i, 6'b0};
    3'd3:   newData = {4'b0, data_i, 5'b0};
    3'd4:   newData = {5'b0, data_i, 4'b0};
    3'd5:   newData = {6'b0, data_i, 3'b0};
    3'd6:   newData = {7'b0, data_i, 2'b0};
    3'd7:   newData = {8'b0, data_i, 1'b0};
    endcase
end

//shift old data
assign oldData =
    shiftHold_r && ~ddr_i   ? data:
    shiftHold_r && ddr_i    ? {data[12:0],  4'b0}:
    shiftDouble_r && ~ddr_i ? {data[1:0],   15'b0}:
    shiftDouble_r && ddr_i  ? {data[4:0],   12'b0}:
    shiftSlow_r             ? {data[7:0],   9'b0}:
    shiftFast_r             ? {data[9:0],   7'b0}:
                              {data[8:0],   8'b0};

//combine new and old data
always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)       data <= '0;
    else                    data <= oldData | newData;
end

//find edge

//  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
//__ _____ ----- ----- ----- ----- _____ _____ __|
// fst | god | slw | bad | fst | god | slw | bad |
//                 | b2  |                 | b1  |


//  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
//__ _____ _____ _____ ----- ----- ----- ----- --|
// vry |   fast    | god |   slow    | vry | bad |
//                                         | b2  |

logic [7:0] edges;
assign edges = data[16:9] ^ data[15:8];

// state detect DDR
logic fastDDR;
logic slowDDR;
logic badDDR;

assign fastDDR = edges[7] | edges[3];
assign slowDDR = edges[5] | edges[1];
assign badDDR =  edges[4] | edges[0];

//state detect simple
logic fast;
logic veryFast;
logic slow;
logic verySlow;
logic bad;

assign fast =       ddr_i ? edges[7] | edges[3] : |edges[6:5];
assign veryFast =   ddr_i ? 1'b0                : edges[7];
assign slow =       ddr_i ? edges[5] | edges[1] : |edges[3:2];
assign verySlow =   ddr_i ? 1'b0                : edges[0];
assign bad =        ddr_i ? edges[4] | edges[0] : edges[0];



//remember fast and slow
logic fast_r;
always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)           fast_r <= 1'b0;
    else if(|edges == 1'b0)     fast_r <= fast_r;   //if no edges, keep
    else if(fast_r == 1'b1)     fast_r <= 1'b0;     //other edge, kill
    else if(fast && ~ddr_i)     fast_r <= 1'b1;     //fast edge
    else if(fastDDR && ddr_i)   fast_r <= 1'b1;     //fast edge; DDR mode
    else                        fast_r <= fast_r;
end

logic slow_r;
always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i == 1'b1)           slow_r <= 1'b0;
    else if(|edges == 1'b0)     slow_r <= slow_r;   //if no edges at all, keep
    else if(slow_r == 1'b1)     slow_r <= 1'b0;     //other edge, kill
    else if(slow  && ~ddr_i)    slow_r <= 1'b1;     //slow edge
    else if(slowDDR  && ddr_i)  slow_r <= 1'b1;     //slow edge; DDR mode
    else                        slow_r <= slow_r;
end

//decide movement
assign shiftFast =
    (fast_r && (fast || bad))
 || veryFast
  ? 1'b1 : 1'b0;

assign shiftSlow =
    (slow_r && (slow || bad))
 || verySlow
  ? 1'b1 : 1'b0;

assign shiftHold = 
    pos == 0
 && shiftSlow == 1'b1
  ? 1'b1 : 1'b0;

assign shiftDouble =
    shiftFast
 && ( (pos == 7 && ~ddr_i)
   || (pos == 3 && ddr_i) )
  ? 1'b1 : 1'b0;

//output

assign data_o = 
    ddr_i ? {data[12], data[8], data[4]}:
            {data[8], data[1], 1'b0}; //take bit 7 bits ahead because fast anyway
assign valid_o = 
    shiftHold_r     ? (ddr_i ? 2'd1 : 2'd0):
    shiftDouble_r   ? (ddr_i ? 2'd3 : 2'd2):
                      (ddr_i ? 2'd2 : 2'd1);

endmodule



// --------________ 0
// __--------______ 1
// ____--------____ 2
// ______--------__ 3
// ________-------- 4
// --________------ 5
// ----________---- 6
// ------________-- 7
