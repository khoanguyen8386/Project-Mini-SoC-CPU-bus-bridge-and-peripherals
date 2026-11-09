`timescale 1ns/1ps

module cpu_abh_wapper (
    input wire HCLK,
    input wire HRESETn,

    //CPU Side Interface
    input wire        mem_req,
    input wire        mem_we,
    input wire [2:0]  mem_size,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    output wire [31:0]mem_rdata,
    output wire       cpu_stall,

    output reg [31:0] HADDR,
    output reg [2:0]  HBURST,
    output reg        HMASTLOCK,
    output reg [3:0]  HPROT,
    output reg [2:0]  HSIZE,
    output reg [1:0]  HTRANS,
    output reg [31:0] HWDATA,
    output reg        HWRITE,
    input wire [31:0] HRDATA,
    input wire        HREADY,
    input wire        HRESP
);

    localparam [1:0] HTRANS_IDLE = 2'b00;
    localparam [1:0] HTRANS_BUSY = 2'b01;
    localparam [1:0] HTRANS_NONSEQ = 2'b10;
    localparam [1:0] HTRANS_SEQ = 2'b11;

    localparam ST_ADDR_PHASE = 1'b0;
    localparam ST_DATA_PHASE = 1'b1;

    reg        state;
    reg [31:0] wdata_latched;

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
        state <= ST_ADDR_PHASE;
        wdata_latched <= 32'h0000_0000;
        end else begin
        case(state)
        ST_ADDR_PHASE: begin
            if(mem_req && HREADY) begin
            state <= ST_DATA_PHASE;
            wdata_latched <= mem_wdata;
            end
            end

            ST_DATA_PHASE : begin
            if (HREADY) begin
            state <= ST_ADDR_PHASE;
            end
        end
    endcase
    end
    end

    always @(*) begin
    if(!HRESETn) begin
    HADDR = 32'h0000_0000;
    HBURST = 3'b000;
    HMASTLOCK = 1'b0;
    HPROT = 4'b0011;
    HSIZE = 3'b010;
    HTRANS = HTRANS_IDLE;
    HWDATA = 32'h0000_0000;
    HWRITE = 1'b01;
    end else if (state == ST_ADDR_PHASE) begin
     HADDR     = mem_req ? mem_addr : 32'h0000_0000;
     HBURST    = 3'b000;        
     HMASTLOCK = 1'b0;
     HPROT     = 4'b0011;       
     HSIZE     = mem_req ? mem_size : 3'b010;
     HTRANS    = mem_req ? HTRANS_NONSEQ : HTRANS_IDLE;
     HWDATA    = 32'h0000_0000;
     HWRITE    = mem_req ? mem_we : 1'b0;
     end else begin
     HADDR     = 32'h0000_0000;
     HBURST    = 3'b000;
     HMASTLOCK = 1'b0;
     HPROT     = 4'b0011;
     HSIZE     = 3'b010;
     HTRANS    = HTRANS_IDLE;
     HWDATA    = wdata_latched; 
     HWRITE    = 1'b0;
     end
     end
     assign cpu_stall = (state == ST_ADDR_PHASE) ? mem_req : ~HREADY;
    assign mem_rdata = HRDATA;

    endmodule