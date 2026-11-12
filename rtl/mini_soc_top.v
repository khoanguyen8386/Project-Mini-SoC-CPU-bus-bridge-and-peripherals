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

        wire [31:0] HRDATA_SRAM;
        wire        HREADY_SRAM;
        wire        HRESP_SRAM;

        wire [31:0] HRDATA_APB;
        wire        HREADYOUT_APB;
        wire        HRESP_APB;

        wire [31:0] PADDR;
        wire        PENABLE;
        wire        PWRITE;
        wire [31:0] PWDATA;
        wire        PSEL_GPIO;
        wire        PSEL_TIMER;
        wire        PSEL_UART;
        wire        PSEL_CLK;

        wire [31:0] PRDATA_GPIO;
        wire        PREADY_GPIO;
        wire [31:0] PRDATA_TIMER;
        wire        PREADY_TIMER;
        wire [31:0] PRDATA_CLK;
        wire        PREADY_CLK;

        wire        timer_irq;
        wire        clk_en_gpio;
        wire        clk_en_timer;
        wire        clk_en_uart;
        wire [31:0] dbg_epc;
        wire        dbg_in_isr;
        
        assign dbg_timer_irq = timer_irq;

        cpu_core_mips u_cpu_core (
            .clk        (HCLK),
            .rst_n      (HRESETn),
            .imem_addr  (imem_addr),
            .imem_rdata (imem_rdata),
            .mem_req    (mem_req),
            .mem_we     (mem_we),
            .mem_size   (mem_size),
            .mem_addr   (mem_addr),
            .mem_wdata  (mem_wdata),
            .mem_rdata  (mem_rdata),
            .cpu_stall  (cpu_stall),
            .timer_irq  (timer_irq),
            .dbg_pc     (dbg_pc),
            .dbg_epc    (dbg_epc),
            dbg_in_isr  (dbg_in_isr)
        );

        cpu_ahb_wrapper u_ahb_master (
            .HCLK       (HCLK),
            .HRESETn    (HRESETn),
            .mem_req    (mem_req),
            .mem_we     (mem_we),
            .mem_size   (mem_size),
            .mem_addr   (mem_addr),
            .mem_wdata  (mem_wdata),
            .mem_rdata  (mem_rdata),
            .cpu_stall  (cpu_stall),
            .HADDR      (HADDR),
            .HBURST     (HBURST),
            .HMASTLOCK  (HMASTLOCK),
            .HPROT      (HPROT),
            .HSIZE      (HSIZE),
            .HTRANS     (HTRANS),
            .HWDATA     (HWDATA),
            .HWRITE     (HWRITE),
            .HRDATA     (HRDATA),
            .HREADY     (HREADY),
            .HRESP      (HRESP)
        );

        