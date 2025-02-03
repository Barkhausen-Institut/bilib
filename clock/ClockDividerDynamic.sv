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

//divides a clock by an input value

module ClockDividerDynamic #(
    parameter DIVIDER_WIDTH = 8
) (
    input   wire logic                      clk_i,
    input   wire logic                      rst_i,
    output  wire logic                      clk_o,
    input   wire logic [DIVIDER_WIDTH-1:0]  divider_i
);

`ifdef RACYICS

    ri_common_clkdiv_by_n #(
        .DIV_WIDTH(DIVIDER_WIDTH)
    ) div (
        .clk_i      (clk_i),
        .reset_n_i  (~rst_i),
        .testmode_i (1'b0),
        .clk_div_o  (clk_o),
        .div_val_i  (divider_i)
    );

`else

    //simulation only
    wire                      clkdiv;
    wire  [DIVIDER_WIDTH-1:0] div_val_minus_1;
    reg                       clkdiv_p;
    reg                       clkdiv_n;
    reg   [DIVIDER_WIDTH-1:0] count;
    wire  [DIVIDER_WIDTH-1:0] next_count;

    reg set_clk;
    reg reset_clk;
    reg [DIVIDER_WIDTH-1:0] div_val_r;

    wire clk_n;
    assign clk_n = ~clk_i;

    assign div_val_minus_1 = div_val_r + {DIVIDER_WIDTH{1'b1}};
    assign next_count = set_clk ? 'b0 : count + 1;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count <= {DIVIDER_WIDTH{1'b0}};
        end else begin
            count <= next_count;
        end
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_val_r <= {DIVIDER_WIDTH{1'b0}};
        end else begin
            div_val_r <= divider_i;
        end
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            set_clk <= 1'd0;
        end else if (next_count == div_val_minus_1) begin
            set_clk <= 1'd1;
        end else begin
            set_clk <= 1'd0;
        end
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            reset_clk <= 1'd0;
        end else if (next_count == {1'b0, div_val_minus_1[DIVIDER_WIDTH-1:1]}) begin
            reset_clk <= 1'd1;
        end else begin
            reset_clk <= 1'd0;
        end
    end

    reg clkdiv_p_in_s;
    always @(count or set_clk or reset_clk or clkdiv_p) begin
        clkdiv_p_in_s = clkdiv_p;
        if (set_clk) begin
            clkdiv_p_in_s = 1'b1;
        end else if (reset_clk) begin
            clkdiv_p_in_s = 1'b0;
        end
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            clkdiv_p <= 1'd0;
        end else begin
            clkdiv_p <= clkdiv_p_in_s;
        end
    end

    reg clkdiv_n_in_s;
    always @(count or set_clk or reset_clk or div_val_r[0] or clkdiv_n) begin
        clkdiv_n_in_s = clkdiv_n;
        if (set_clk) begin
            clkdiv_n_in_s = 1'b1;
        end else if (reset_clk) begin
            clkdiv_n_in_s = ~div_val_r[0];
        end
    end

    always @(posedge clk_n or posedge rst_i) begin
        if (rst_i) begin
            clkdiv_n <= 1'd0;
        end else begin
            clkdiv_n <= clkdiv_n_in_s;
        end
    end
    assign clkdiv = clkdiv_p & clkdiv_n;

    assign clk_o = (div_val_r == {{(DIVIDER_WIDTH-1){1'b0}}, 1'b1}) ? clk_i : clkdiv;

`endif

endmodule