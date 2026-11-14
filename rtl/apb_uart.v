<<<<<<< HEAD
`timescale 1ns / 1ps
        module apb_uart # (
            parameter integer CLK_FREQ = 50_000_000,
            parameter integer BAUD_RATE = 115200
        ) (
            input  wire              PCLK,
            input  wire              PRESETn,
            input  wire              clk_en_uart,

            input  wire              PSEL,
            input  wire              PENABLE.
            input  wire              PWRITE,
            input  wire [31:0]       PADDR,
            input  wire [31:0]       PWDATA,
            output reg  [31:0]       PRDATA,
            output wire              PREADY,

            output reg               uart_txd,
            input wire               uart_rxd
        );

        localparam [15:0] DEFAULT_DIV = (CLK_FREQ / BAUD_RATE);

        reg [1:0]  ctrl_reg;
        reg [15:0] baud_div_reg;

        wire tx_en = ctrl_reg[0];
        wire rx_en = ctrl_reg[1];

        wire apb_write = PSEL && PENABLE && PWRITE;
        wire apb_read = PSEL && !PWRITE;
        wire apb_read_access = PSEL && PENABLE && !PWRITE;

        localparam [1:0] TX_IDLE  = 2'b00;
        localparam [1:0] TX_START = 2'b01;
        localparam [1:0] TX_DATA  = 2'b10;
        localparam [1:0] TX_STOP  = 2'b11;

        reg [1:0]  tx_state;
        reg [15:0] tx_baud_cnt;
        reg [2:0]  tx_bit_idx;
        reg [7:0]  tx_shift_reg;

        wire tx_busy  = (tx_state != TX_IDLE);
        wire tx_ready = (tx_state == TX_IDLE);

        localparam [1:0] RX_IDLE  = 2'b00;
        localparam [1:0] RX_START = 2'b01;
        localparam [1:0] RX_DATA  = 2'b10;
        localparam [1:0] RX_STOP  = 2'b11;

        reg         rx_sync1, rx_sync2;
        reg [1:0]   rx_state;
        reg [15:0]  rx_baud_cnt;
        reg [2:0]   rx_bit_idx;
        reg [7:0]   rx_shift_reg;
        reg [7:0]   rx_data_reg;
        reg         rx_valid_reg;

        always @(posedge PCLK or negedge PRESETn) begin
            if(!PRESETn) begin
                ctrl_reg        <= 2'b11;
                baud_div_reg    <= (DEFAULT_DIV < 16'd4) ? 16'd4 :DEFAULT_DIV;
                
                tx_state        <= TX_IDLE;
                tx_baud_cnt     <= 16'd0;
                tx_bit_idx      <= 3'd0;
                tx_shift_reg    <= 8'h00;
                uart_txd        <= 1'b1;

                rx_sync1        <= 1'b1;
                rx_sync2        <= 1'b1;
                rx_state        <= RX_IDLE;
                rx_baud_cnt     <= 16'd0;
                rx_bit_idx      <= 3'd0;
                rx_shift_reg    <= 8'h00;
                rx_data_reg     <= 8'h00;
                rx_valid_reg    <= 1'b0;
        end else if (clk_en_uart) begin
                rx_sync1        <= uart_rxd;
                rx_sync2        <= rx_sync1;

                if(apd_write) begin
                    case (PADDR[7:0])
                        8'h08: if (PWDATA[1]) rx_valid_reg <= 1'b0;
                        8'h0C: ctrl_reg <= PWDATA [1:0];
                        8'h10: baud_div_reg <= (PWDATA[15:0] < 16'd4) ? 16'd4 : PWDATA[15:0];
                        default: ;
                    endcase
                end
                
=======
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
>>>>>>> e544253f7f3e6ffa92ae957dd6aecaff2b8d32f1
