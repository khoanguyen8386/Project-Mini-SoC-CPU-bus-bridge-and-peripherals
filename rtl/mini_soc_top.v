`timescale 1ns / 1ps
    module mini_soc_top # (
        parameter integer CLK_FREQ       = 50_000_000,
        parameter integer UART_BAUD_RATE = 115200,
        parameter [31:0]  TIMER_RELOAD   = 32'd50_000_000,
        parameter         MEM_INIT_HEX   = "../sw/firmware.hex"
        parameter         MEM_INIT_MIF   = "../sw/firmware.mif"
    )(
        input wire        HCLK,
        input wire        HRESETn,

        input wire [17:0] gpio_sw_in,
        output wire[17:0] gpio_ledr_out,

        output wire uart_txd,
        input wire uart_rxd,

        output wire [31:0] dbg_pc,
        output wire        dbg_timer_irq

    );

        wire [31:0] imem_addr;
        wire [31:0] imem_rdata;

        wire        mem_req;
        wire        mem_we;
        wire [2:0]  mem_size;
        wire [31:0] mem_addr;
        wire [31:0] mem_rdata;
        wire        cpu_stall;

        wire [31:0] HADDR;
        wire [2:0]  HBURST;
        wire        HMASTLOCK;
        wire [3:0]  HPROT;
        wire [2:0]  HSIZE;
        wire [1:0]  HTRANS;
        wire [31:0] HWDATA;
        wire        HWRITE;
        wire [31:0] HRDATA;
        wire        HREADY;
        wire        HRESP;

        wire        HSEL_SRAM;
        wire        HSEL_APB;
        wire        HSEL_DEF;

        