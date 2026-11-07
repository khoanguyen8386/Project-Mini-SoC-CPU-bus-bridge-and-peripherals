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
    //instruction field
    wire [5:0] opcode = imem_rdata[31:26];
    wire [4:0] rs = imem_rdata[25:21];
    wire [4:0] rt = imem_rdata[20:16];
    wire [4:0] rd = imem_rdata[15:11];
    wire [4:0] shamt = imem_rdata[10:6];
    wire [5:0] funct = imem_rdata[5:0];
    wire [15:0] imm16 = imem_rdata[15:0];
    wire [25:0] jaddr = imem_rdata[25:0];

    wire [31:0] sign_ext_imm ={{16{imm16[15]}}, imm16};
    wire [31:0] zero_ext_imm = {16'h0000, imm16};
    wire [31:0] upper_imm = {imm16, 16'h0000};