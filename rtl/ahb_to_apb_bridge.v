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
    
endmodule