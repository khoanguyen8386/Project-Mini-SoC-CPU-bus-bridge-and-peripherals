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
                
                if(apd_read_access && (PADDR[7:0] == 8'h04)) begin
                    rx_valid_reg <= 1'b0;
                end

                case (tx_state)
                    TX_IDLE: begin
                        uart_txd        <= 1'b1;
                        tx_baud_cnt     <= 16'd0;
                        tx_bit_idx      <= 3'd0;
                        if (apd_write && (PADDR[7:0] == 8'h00) && tx_en) begin
                                tx_shift_reg    <= PWDATA [7:0];
                                tx_state        <= TX_START;
                                uart_txd        <= 1'b0;
                            end
                        end
                        
                        TX_START: begin
                            uart_txd <= 1'b0;
                            if (tx_baud_cnt == baud_div_reg - 16'b1) begin
                                tx_baud_cnt <= 16'd0;
                                tx_state    <= TX_DATA;
                                uart_txd    <= tx_shift_reg[0];
                            end else begin
                                tx_baud_cnt <= tx_baud_cnt + 16'd1;
                            end
                        end

                        TX_DATA: begin
                            uart_txd <= tx_shift_reg[tx_bit_idx];
                            if(tx_baud_cnt == baud_div_reg - 16'd1) begin
                                tx_baud_cnt <= 16'd0;
                                if(tx_bit_idx == 3'd7) begin
                                    tx_bit_idx <= 3'd0;
                                    tx_state   <= TX_STOP;
                                    uart_txd   <= 1'b1;
                                end else begin
                                    tx_bit_idx <= tx_bit_idx + 3'd1;
                                end
                            end else begin
                                tx_baud_cnt <= tx_baud_cnt + 16'd1;
                            end
                        end

                        TX_STOP: begin
                            uart_txd <= 1'b1;
                            if (tx_baud_cnt == baud_div_reg - 16'd1) begin
                                tx_baud_cnt <= 16'd0;
                                tx_state    <= TX_IDLE;
                            end else begin
                                tx_baud_cnt <= tx_baud_cnt + 16'd1;
                            end
                        end
                    endcase

                    case (rx_state)
                         RX_IDLE: begin
                            rx_baud_cnt <= 16'd0;
                            rx_bit_idx  <= 3'd0;
                            if (rx_en && (rx_sync2 == 1'b0)) begin
                                rx_state <= RX_START;
                            end
                        end

                        RX_START: begin
                            if (rx_baud_cnt == (baud_div_reg >> 1) - 16'd1) begin
                                rx_baud_cnt <= 16'd0;
                                if (rx_sync2 == 1'b0) begin
                                    rx_state <= RX_DATA;
                                end else begin
                                    rx_state <= RX_IDLE;
                                end
                            end else begin
                                rx_baud_cnt <= rx_baud_cnt + 16'd1;
                            end
                        end

                        RX_DATA: begin
                            if (rx_baud_cnt == baud_div_reg - 16'd1) begin
                                rx_baud_cnt                 <= 16'd0;
                                rx_shift_reg[rx_bit_idx]    <= rx_sync2;
                                if (rx_bit_idx == 3'd7) begin
                                    rx_bit_idx <= 3'd0;
                                    rx_state   <= RX_STOP;
                                end else begin
                                    rx_bit_idx <= rx_bit_idx + 3'd1;
                                end
                            end else begin
                                rx_baud_cnt <= rx_baud_cnt + 16'd1;
                            end
                        end

                        RX_STOP: begin
                            if (rx_baud_cnt == baud_div_reg - 16'd1) begin
                                rx_baud_cnt  <= 16'd0;
                                rx_state     <= RX_IDLE;
                                rx_data_reg  <= rx_shift_reg;
                                rx_valid_reg <= 1'b1;
                            end else begin
                                rx_baud_cnt  <= rx_baud_cnt + 16'd1;
                            end
                        end
                    endcase
                end
            end

            always @(*) begin
                PRDATA = 32'h0000_0000;
                if (apd_read) begin
                    case (PADDR[7:0])
                        8'h04: PRDATA = {24'h0, rx_data_reg};
                        8'h08: PRDATA = {29'h0, tx_ready, rx_valid_reg, tx_busy};
                        8'h0C: PRDATA = {30'h0, ctrl_reg};
                        8'h10: PRDATA = {16'h0, baud_div_reg};
                        default: PRDATA = 32'h0000_0000;
                    endcase
                end
            end

            assign PREADY = 1'b1;

            endmodule