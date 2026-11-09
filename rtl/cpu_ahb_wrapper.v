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