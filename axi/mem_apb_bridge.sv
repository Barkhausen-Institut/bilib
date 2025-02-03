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

//assumptions:
// - APB interface widths are smaller or equal than mem interface (APB_DATA_WIDTH <= MEM_DATA_WIDTH)
// - no memory mapping, i.e. only lower bits are assigned to data signals (e.g., apb_pwdata = mem_wdata[APB_DATA_WIDTH-1:0])
// - mem_rreq_i indicates a read request of <= MEM_DATA_WIDTH bits -> if apb_prdata_i is ready, mem_rdata_avail_o is asserted to inform mem IF

module mem_apb_bridge #(
    parameter MEM_ADDR_WIDTH = 32,
    parameter MEM_DATA_WIDTH = 128,
    parameter APB_ADDR_WIDTH = 16,
    parameter APB_DATA_WIDTH = 32
)(
    input  wire                        clk_i,
    input  wire                        reset_n_i,

    output wire                 [31:0] mem_apb_error_o,    //0: ok, >0: error

	//Mem IF
    input  wire                        mem_en_i,
    input  wire                        mem_rreq_i,
    input  wire   [MEM_ADDR_WIDTH-1:0] mem_addr_i,
    input  wire [MEM_DATA_WIDTH/8-1:0] mem_wben_i,
    input  wire   [MEM_DATA_WIDTH-1:0] mem_wdata_i,
    output wire   [MEM_DATA_WIDTH-1:0] mem_rdata_o,
    output reg                         mem_rdata_avail_o,
    output wire                        mem_stall_o,

    //APB Master IF
    output wire   [APB_ADDR_WIDTH-1:0] apb_paddr_o,
    output wire   [APB_DATA_WIDTH-1:0] apb_pwdata_o,
    output reg                         apb_pwrite_o,
    output wire [APB_DATA_WIDTH/8-1:0] apb_pstrb_o,
    output reg                         apb_psel_o,
    output reg                         apb_penable_o,
    input  wire                        apb_pready_i,
    input  wire   [APB_DATA_WIDTH-1:0] apb_prdata_i,
    input  wire                        apb_pslverr_i
);


    localparam NUM_STATES = 3;
    localparam STATE_WIDTH = $clog2(NUM_STATES);
    localparam [STATE_WIDTH-1:0] S_IDLE   = 0;
    localparam [STATE_WIDTH-1:0] S_SETUP  = 1;
    localparam [STATE_WIDTH-1:0] S_ACCESS = 2;

    reg [STATE_WIDTH-1:0] state, next_state;
    reg [31:0] r_error, rin_error;

    reg   [APB_ADDR_WIDTH-1:0] r_apb_paddr, rin_apb_paddr;
    reg   [APB_DATA_WIDTH-1:0] r_apb_prdata, rin_apb_prdata;
    reg   [APB_DATA_WIDTH-1:0] r_apb_pwdata, rin_apb_pwdata;
    reg [APB_DATA_WIDTH/8-1:0] r_apb_pstrb, rin_apb_pstrb;

    wire apb_write = |mem_wben_i;


    always @(posedge clk_i or negedge reset_n_i) begin
        if (reset_n_i == 1'b0) begin
            state <= S_IDLE;
            r_error <= 32'h0;

            r_apb_paddr <= {APB_ADDR_WIDTH{1'b0}};
            r_apb_prdata <= {APB_DATA_WIDTH{1'b0}};
            r_apb_pwdata <= {APB_DATA_WIDTH{1'b0}};
            r_apb_pstrb <= {(APB_DATA_WIDTH/8){1'b0}};
        end
        else begin
            state <= next_state;
            r_error <= rin_error;

            r_apb_paddr <= rin_apb_paddr;
            r_apb_prdata <= rin_apb_prdata;
            r_apb_pwdata <= rin_apb_pwdata;
            r_apb_pstrb <= rin_apb_pstrb;
        end
    end

    
    //---------------
    //state machine
    always @* begin
        next_state = state;

        rin_apb_paddr = r_apb_paddr;
        rin_apb_prdata = r_apb_prdata;
        rin_apb_pwdata = r_apb_pwdata;
        rin_apb_pstrb = r_apb_pstrb;

        mem_rdata_avail_o = 1'b0;

        apb_psel_o = 1'b0;
        apb_penable_o = 1'b0;
        apb_pwrite_o = 1'b0;

        rin_error = r_error;

        case (state)

            //wait for incoming mem access
            S_IDLE: begin
                rin_apb_paddr = mem_addr_i[APB_ADDR_WIDTH-1:0];
                rin_apb_pwdata = mem_wdata_i[APB_DATA_WIDTH-1:0];
                rin_apb_pstrb = mem_wben_i[APB_DATA_WIDTH/8-1:0];

                //normal write or read request
                if ((mem_en_i && apb_write) || mem_rreq_i) begin
                    next_state = S_SETUP;
                end
            end

            S_SETUP: begin
                apb_psel_o = 1'b1;
                apb_pwrite_o = apb_write;
                next_state = S_ACCESS;
            end

            S_ACCESS: begin
                apb_psel_o = 1'b1;
                apb_penable_o = 1'b1;
                apb_pwrite_o = apb_write;
                
                if (apb_pready_i) begin
                    if (apb_pslverr_i) begin
                        rin_error = r_error + 1;
                    end

                    //if it was a read, store this data and inform mem IF
                    rin_apb_prdata = apb_prdata_i;
                    mem_rdata_avail_o = 1'b1;

                    next_state = S_IDLE;
                end
            end

            default: next_state = S_IDLE;
        endcase
    end


    assign apb_paddr_o = r_apb_paddr;
    assign apb_pwdata_o = r_apb_pwdata;
    assign apb_pstrb_o = r_apb_pstrb;

    assign mem_stall_o = (state != S_IDLE);
    assign mem_rdata_o = {{(MEM_DATA_WIDTH-APB_DATA_WIDTH){1'b0}}, r_apb_prdata};

    assign mem_apb_error_o = r_error;


endmodule
