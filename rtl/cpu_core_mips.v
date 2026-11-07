`timescale 1ns/1ps

module cpu_core_mips (
    input wire clk,
    input wire rst_n,
    
    // instruction memory port 
    output reg [31:0] imem_addr, 
    input wire [31:0] imem_rdata,
    
    // data memory/ bus wrapper interface
    output wire mem_reg,
    output wire mem_we,
    output wire [2:0] mem_size,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    input wire cpu_stall,
    
    //hardware interrupt input (from APB timer)
    input wire time_irq,

    //debug for output
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_epc,
    output wire dbg_in_isr
);
