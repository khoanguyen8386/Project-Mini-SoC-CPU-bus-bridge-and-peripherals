`timescale 1ns / 1ps
module de2_115_wrapper (
    input wire          CLOCK_50,
    input wire [0:0]    KEY,
    input wire [17:0]   SW,
    output wire[17:0]   LEDR,
    output wire         UART_TXD,
    input wire          UART_RXD 
);

    reg rst_sync_ff1;
    reg rst_sync_ff2;

    always @(posedge CLOCK_50 or negadge KEY[0]) begin
        if(!KEY[0]) begin
            rst_sync_ff1 <= 1'b0;
            rst_sync_ff2 <= 1'b0;
        end else begin
            rst_sync_ff1 <= 1'b1;
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end

    wire HRESETn = rst_sync_ff2;
    wire [31:0] unused_dbg_pc;
    wire        unused_dbg_irq;

    mini_soc_top #(
        .CLK_FREQ           (50_000_000),
        .UART_BAUD_RATE     (115200)
        .TIMER_RELOAD       (32'd50_000_000)
        .MEM_INIT_HEX       ("../sw/firmware.hex"),
        .MEM_INIT_MIF       ("../sw/firmware.mif")
    ) u_mini_soc_top (
        .HCLK               (CLOCK_50)
        .HRESETn            (HRESETn),
        .gpio_sw_in         (SW),
        .gpio_ledr_out      (LEDR),
        .uart_txd           (UART_RXD),
        .UART_RXD           (UART_RXD),
        .dbg_pc             (unused_dbg_pc),
        .dbg_timer_irq      (unused_dbg_irq)
    );

    endmodule

    module de2_115_top (
        
    )