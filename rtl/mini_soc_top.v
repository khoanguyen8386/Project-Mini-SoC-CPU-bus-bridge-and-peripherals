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

        ahb_lite_interconnect u_ahb_interconnect (
            .HCLK           (HCLK),
            .HRESETn        (HRESETn),
            .HADDR          (HADDR),
            .HTRANS         (HTRANS),
            .HSEL_SRAM      (HSEL_SRAM),
            .HSEL_APB       (HSEL_APB),
            .HRDATA_SRAM    (HRDATA_SRAM),
            .HREADYOUT_SRAM (HREADYOUT_SRAM),
            .HRESP_SRAM     (HRESP_SRAM),
            .HRDATA_APB     (HRDATA_APB),
            .HREADYOUT_SRAM (HREADYOUT_SRAM),
            .HRESP_APB      (HRESP_APB),
            .HRDATA         (HRDATA),
            .HREADY         (HREADY),
            .HRESP          (HRESP)
        );

        onchip_sram #(
            .MEM_INIT_HEX   (MEM_INIT_HEX),
            .MEM_INIT_MIF   (MEM_INIT_MIF)
        ) u_onchip_sram (
            .HCLK           (HCLK),
            .HRESETn        (HRESETn),
            .imem_addr      (imem_addr),
            .imem_rdata     (imem_rdata),
            .HSEL           (HSEL_SRAM),
            .HADDR          (HADDR),
            .HTRANS         (HTRANS),
            .HSIZE          (HSIZE),
            .HWRITE         (HWRITE),
            .HREADY         (HREADY),
            .HWDATA         (HWDATA),
            .HRDATA         (HRDATA_SRAM),
            .HREADYOUT      (HREADYOUT_SRAM),
            .HRESP          (HRESP_SRAM)
        );

        ahb_to_apb_bridge u_ahb_to_apb_bridge (
            .HCLK           (HCLK)
            .HRESETn        (HRESETn),
            .HSEL           (HSEL_APB),
            .HADDR          (HADDR),
            .HSIZE          (HSIZE),
            .HWRITE         (HWRITE),
            .HREADY         (HREADY),
            .HWDATA         (HWDATA),
            .HRDATA         (HRDATA_APB),
            .HREADYOUT      (HREADYOUT_APB),
            .HRESP          (HRESP_APB),
            .PADDR          (PADDR),
            .PENABLE        (PENABLE),
            .PWRITE         (PWRITE),
            .PWDATA         (PWDATA),
            .PSEL_GPIO      (PSEL_GPIO),
            .PSEL_TIMER     (PSEL_TIMER),
            .PSEL_UART      (PSEL_UART),
            .PSEL_CLK       (PSEL_CLK),
            PRDATA_GPIO     (PRDATA_GPIO),
            PREADY_TIMER    (PREADY_TIMER),
            
        )