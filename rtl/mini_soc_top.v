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