'`timescale 1ns/1ps
module ahb_to_apb_bridge(
    input wire HCLK,
    input wire HRESETn,
    
    //AHB-lite
    input wire HSEL,
    input wire [31:0] HADDR,
    input wire [1:0] HTRANS,
    input wire [2:0] HSIZE,
    input wire HWRITE,
    input wire HREADY,
    input wire [31:0] HWDATA,
    output reg [31:0] HRDATA,
    output reg HREADYOUT, 
    output wire HRESP,

    //APB3 master interface
    output reg [31:0] PADDR,
    output reg PENABLE,
    output reg PWRITE,
    output reg [31:0] PWDATA,
    output reg PSEL_GPIO,
    output reg PSEL_TIMER,
    output reg PSEL_UART,
    output reg PSEL_CLK,

    //APB3 slave inputs 
    input wire [31:0] PRDATA_GPIO,
    input wire PREADY_GPIO,
    input wire [31:0] PRDATA_TIMER,
    input wire PREADY_TIMER,
    input wire [31:0] PRDATA_UART,
    input wire PREADY_UART, 
    input wire [31:0] PRDATA_CLK,
    input wire PREADY_CLK
);
    localparam [1:0] ST_IDLE = 2'b00;
    localparam [1:0] ST_SETUP = 2'b01;
    localparam [1:0] ST_ACCESS = 2'b10;
    reg [1:0] state;
    reg[31:0] haddr_reg;
    reg hwrite_reg;
    wire valid_ahb_req = HSEL && HREADY && HTRANS[1];

    //secondary APB address decoder 
    wire [1:0] apb_slave_idx = PADDR[13:12];
    reg [31:0] prdata_muxl;
    reg pready_mux;
    always @(*) begin
        case (apb_slave_idx)
            2'b00: begin
                prdata_mux = PRDATA_GPIO;
                pready_mux = PREADY_GPIOO;
            end 
            2'b01: begin
                prdata_mux = PRDATA_TIMER;
                pready_mux = PREADY_TIMER:
            end
            2'b10: begin
                prdata_mux = PRDATA_UART;
                pready_mux = PREADY_MUX;
            end
            default: begin
                prdata_mux = PRDATA_CLK;
                pready_mux = PREADY_CLK;
            end
        endcase
    end

    //bridge state machine 
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            state <= ST_IDLE;
            haddr_reg <= 32'h0000_0000;
            hwrite_reg <= 1'b0;
            PADDR <= 32'h0000_0000;
            PWRITE <= 1'b0;
            PWDATA <= 32'h0000_0000;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (valid_ahb_reg) begin
                        state <= ST_SETUP;
                        haddr_reg <= HADDR;
                        hwrite_reg <= HWRITE;
                        PADDR <= HADDR;
                        PWRITE <= HWRITE;
                    end
                end
                ST_SETUP: begin
                    PWDATA <= HWDATA;
                    state <= ST_ACCESS;
                end
                ST_ACESS: begin
                    if(pready_mux) begin
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE:
            endcase
        end
    end

    //APB and AHB output 
    always @(*) begin
        PSEL_GPIO = 1'b0;
        PSEL_TIMER = 1'b0;
        PSEL_UART = 1'b0;
        PSEL_CLK = 1'b0;
        PENABLE = 1'b0;
        HREADYOUT = 1'b1;
        HRDATA = prdata_mux;
        case (state)
            ST_IDLE: begin
                HREADYOUT = 1'b1;
            end
            ST_SETUP: begin
                HREADYOUT = 1'b0;
                PENABLE = 1'b0;
                PSEL_GPIO = (PADDR[13:12] == 2'b00);
                PSEL_TIMER = (PADDR[13:12] == 2'b01);
                PSEL_UART = (PADDR[13:12] == 2'b10);
                PSEL_CLK = (PADDR[13:12] == 2'b11);
            end
            ST_ACCESS: begin
                HREADYOUT = pready_mux;
                PENABLE = 1'b1;
                PSEL_GPIO = (PADDR[13:12] == 2'b00);
                PSEL_TIMER = (PADDR[13:12] == 2'h01);
                PSEL_UART = (PADDR[13:12] == 2'h10);
                PSEL_CLK = (PADDR[13:12] == 2'h11);
            end
            default: 
        endcase
    end
    assign HRESP = 1'b0;
endmodule