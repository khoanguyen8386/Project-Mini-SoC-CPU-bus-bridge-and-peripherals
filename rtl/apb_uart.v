'`timescale 1ns/1ps
module apb_uart #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input wire PCLK,
    input wire PRESETn,
    input wire clk_en_uart,

    //apb slave interface
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,

    //PIN_G9 TXD, PIN_G12 RXD on DE2-115
    output reg uart_txd,
    input wire uart_rxd
);
    localparam [15:0] DEFAULT_DIV = (CLK_FREQ/BAUD_RATE);

    //control & band divider registers
    reg [1:0] ctrl_reg;
    reg [15:0] baud_div_reg;
    wire tx_en = ctrl_reg[0];
    wire rx_en = ctrl_reg[1];
    wire apb_write = PSEL && PENABLE && PWRITE;
    wire apb_read = PSEL && !PWRITE;
    wire apb_read_access = PSEL && PENABLE && !PWRITE;

    //uart transmitter 
    localparam [1:0] TX_IDLE = 2'b00;
    localparam [1:0] TX_START = 2'b01;
    localparam [1:0] TX_DATA  = 2'b10;
    localparam [1:0] TX_STOP  = 2'b11;
    reg [1:0]  tx_state;
    reg [15:0] tx_baud_cnt;
    reg [2:0]  tx_bit_idx;
    reg [7:0]  tx_shift_reg;
    wire tx_busy  = (tx_state != TX_IDLE);
    wire tx_ready = (tx_state == TX_IDLE);


endmodule