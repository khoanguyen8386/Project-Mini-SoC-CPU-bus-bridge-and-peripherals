`timescale 1ns / 1ps
module de2_115_wrapper (
    input wire          CLOCK_50,
    input wire [0:0]    KEY,
    input wire [17:0]   SW,
    output wire [17:0]  LEDR,
    output wire [6:0]   HEX0,
    output wire [6:0]   HEX1,
    output wire [6:0]   HEX2,
    output wire [6:0]   HEX3,
    output wire [6:0]   HEX4,
    output wire [6:0]   HEX5,
    output wire [6:0]   HEX6,
    output wire [6:0]   HEX7,
    output wire         LCD_ON,
    output wire         LCD_BLON,
    output wire         LCD_RW,
    output wire         LCD_EN,
    output reg          LCD_RS,
    output reg  [7:0]   LCD_DATA,
    output wire         UART_TXD,
    input wire          UART_RXD 
);

    reg rst_sync_ff1;
    reg rst_sync_ff2;

    always @(posedge CLOCK_50 or negedge KEY[0]) begin
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
        .UART_BAUD_RATE     (115200),
        .TIMER_RELOAD       (32'd50_000_000),
        .MEM_INIT_HEX       ("../sw/firmware.hex"),
        .MEM_INIT_MIF       ("../sw/firmware.mif")
    ) u_mini_soc_top (
        .HCLK               (CLOCK_50),
        .HRESETn            (HRESETn),
        .gpio_sw_in         (SW),
        .gpio_ledr_out      (LEDR),
        .uart_txd           (UART_TXD),
        .uart_rxd           (UART_RXD),
        .dbg_pc             (unused_dbg_pc),
        .dbg_timer_irq      (unused_dbg_irq)
    );

    // =========================================================================
    // 1. 16-bit Binary to 5-Digit BCD Converter (Double-Dabble Algorithm)
    // =========================================================================
    wire [15:0] cpu_result = LEDR[15:0];
    wire [1:0]  cpu_mode   = SW[17:16];
    wire        is_dec_mode = (cpu_mode == 2'b01) || (cpu_mode == 2'b10);

    reg [19:0] bcd_digits;
    integer b;
    always @(*) begin
        bcd_digits = 20'd0;
        for (b = 15; b >= 0; b = b - 1) begin
            if (bcd_digits[3:0]   >= 4'd5) bcd_digits[3:0]   = bcd_digits[3:0]   + 4'd3;
            if (bcd_digits[7:4]   >= 4'd5) bcd_digits[7:4]   = bcd_digits[7:4]   + 4'd3;
            if (bcd_digits[11:8]  >= 4'd5) bcd_digits[11:8]  = bcd_digits[11:8]  + 4'd3;
            if (bcd_digits[15:12] >= 4'd5) bcd_digits[15:12] = bcd_digits[15:12] + 4'd3;
            if (bcd_digits[19:16] >= 4'd5) bcd_digits[19:16] = bcd_digits[19:16] + 4'd3;
            bcd_digits = {bcd_digits[18:0], cpu_result[b]};
        end
    end

    // =========================================================================
    // 2. 8-Digit 7-Segment Display Decoder (HEX7..HEX0, Active-Low)
    // =========================================================================
    function [6:0] seg7 (input [3:0] nib);
        case (nib)
            4'h0: seg7 = 7'b1000000;
            4'h1: seg7 = 7'b1111001;
            4'h2: seg7 = 7'b0100100;
            4'h3: seg7 = 7'b0110000;
            4'h4: seg7 = 7'b0011001;
            4'h5: seg7 = 7'b0010010;
            4'h6: seg7 = 7'b0000010;
            4'h7: seg7 = 7'b1111000;
            4'h8: seg7 = 7'b0000000;
            4'h9: seg7 = 7'b0010000;
            4'hA: seg7 = 7'b0001000;
            4'hB: seg7 = 7'b0000011;
            4'hC: seg7 = 7'b1000110;
            4'hD: seg7 = 7'b0100001;
            4'hE: seg7 = 7'b0000110;
            4'hF: seg7 = 7'b0001110;
        endcase
    endfunction

    assign HEX0 = seg7(is_dec_mode ? bcd_digits[3:0]   : cpu_result[3:0]);
    assign HEX1 = seg7(is_dec_mode ? bcd_digits[7:4]   : cpu_result[7:4]);
    assign HEX2 = seg7(is_dec_mode ? bcd_digits[11:8]  : cpu_result[11:8]);
    assign HEX3 = seg7(is_dec_mode ? bcd_digits[15:12] : cpu_result[15:12]);
    assign HEX4 = is_dec_mode ? seg7(bcd_digits[19:16]) : 7'b1111111;
    assign HEX5 = seg7({2'b00, cpu_mode});
    assign HEX6 = seg7(unused_dbg_pc[3:0]);
    assign HEX7 = seg7(unused_dbg_pc[7:4]);

    // =========================================================================
    // 3. HD44780 16x2 Character LCD Controller
    //    Line 1: "LKKN DND MINISOC"
    //    Line 2: Live Mode & Output (e.g. "M1:FIB OUT:06765")
    // =========================================================================
    assign LCD_ON   = 1'b1;
    assign LCD_BLON = 1'b1;
    assign LCD_RW   = 1'b0;

    function [7:0] hex_to_ascii (input [3:0] nib);
        hex_to_ascii = (nib < 4'd10) ? (8'h30 + {4'd0, nib}) : (8'h37 + {4'd0, nib});
    endfunction

    wire [7:0] d4_ascii = is_dec_mode ? hex_to_ascii(bcd_digits[19:16]) : " ";
    wire [7:0] d3_ascii = hex_to_ascii(is_dec_mode ? bcd_digits[15:12] : cpu_result[15:12]);
    wire [7:0] d2_ascii = hex_to_ascii(is_dec_mode ? bcd_digits[11:8]  : cpu_result[11:8]);
    wire [7:0] d1_ascii = hex_to_ascii(is_dec_mode ? bcd_digits[7:4]   : cpu_result[7:4]);
    wire [7:0] d0_ascii = hex_to_ascii(is_dec_mode ? bcd_digits[3:0]   : cpu_result[3:0]);

    reg [15:0] lcd_cnt;
    reg [5:0]  lcd_step;

    always @(posedge CLOCK_50 or negedge HRESETn) begin
        if (!HRESETn) begin
            lcd_cnt  <= 16'd0;
            lcd_step <= 6'd0;
        end else begin
            lcd_cnt <= lcd_cnt + 16'd1;
            if (lcd_cnt == 16'hFFFF) begin
                if (lcd_step == 6'd38)
                    lcd_step <= 6'd5; // Loop back to refresh Line 1 & Line 2
                else
                    lcd_step <= lcd_step + 6'd1;
            end
        end
    end

    assign LCD_EN = (lcd_cnt[15:14] == 2'b01);

    always @(*) begin
        LCD_RS   = 1'b1;
        LCD_DATA = " ";
        case (lcd_step)
            // --- LCD Initialization Commands ---
            6'd0:  begin LCD_RS = 1'b0; LCD_DATA = 8'h38; end // 8-bit, 2 lines, 5x7
            6'd1:  begin LCD_RS = 1'b0; LCD_DATA = 8'h0C; end // Display ON, Cursor OFF
            6'd2:  begin LCD_RS = 1'b0; LCD_DATA = 8'h01; end // Clear Display
            6'd3:  begin LCD_RS = 1'b0; LCD_DATA = 8'h06; end // Entry Mode Increment
            6'd4:  begin LCD_RS = 1'b0; LCD_DATA = 8'h06; end // Extra settle cycle

            // --- Line 1: "LKKN DND MINISOC" ---
            6'd5:  begin LCD_RS = 1'b0; LCD_DATA = 8'h80; end // Line 1 Col 0
            6'd6:  LCD_DATA = "L";
            6'd7:  LCD_DATA = "K";
            6'd8:  LCD_DATA = "K";
            6'd9:  LCD_DATA = "N";
            6'd10: LCD_DATA = " ";
            6'd11: LCD_DATA = "D";
            6'd12: LCD_DATA = "N";
            6'd13: LCD_DATA = "D";
            6'd14: LCD_DATA = " ";
            6'd15: LCD_DATA = "M";
            6'd16: LCD_DATA = "I";
            6'd17: LCD_DATA = "N";
            6'd18: LCD_DATA = "I";
            6'd19: LCD_DATA = "S";
            6'd20: LCD_DATA = "O";
            6'd21: LCD_DATA = "C";

            // --- Line 2: Mode Name & Live Output ---
            6'd22: begin LCD_RS = 1'b0; LCD_DATA = 8'hC0; end // Line 2 Col 0
            6'd23: LCD_DATA = SW[15] ? "P" : "M";
            6'd24: LCD_DATA = SW[15] ? "A" : (8'h30 + {6'd0, cpu_mode});
            6'd25: LCD_DATA = SW[15] ? "U" : ":";
            6'd26: LCD_DATA = SW[15] ? "S" : ((cpu_mode == 2'd0) ? "K" : (cpu_mode == 2'd1) ? "F" : (cpu_mode == 2'd2) ? "M" : "L");
            6'd27: LCD_DATA = SW[15] ? "E" : ((cpu_mode == 2'd0) ? "I" : (cpu_mode == 2'd1) ? "I" : (cpu_mode == 2'd2) ? "U" : "F");
            6'd28: LCD_DATA = SW[15] ? "D" : ((cpu_mode == 2'd0) ? "T" : (cpu_mode == 2'd1) ? "B" : (cpu_mode == 2'd2) ? "L" : "S");
            6'd29: LCD_DATA = SW[15] ? (is_dec_mode ? " " : "!") : ((cpu_mode == 2'd0) ? "T" : (cpu_mode == 2'd3) ? "R" : " ");
            6'd30: LCD_DATA = is_dec_mode ? "O" : " ";
            6'd31: LCD_DATA = is_dec_mode ? "U" : "O";
            6'd32: LCD_DATA = is_dec_mode ? "T" : "U";
            6'd33: LCD_DATA = is_dec_mode ? ":" : "T";
            6'd34: LCD_DATA = is_dec_mode ? d4_ascii : ":";
            6'd35: LCD_DATA = d3_ascii;
            6'd36: LCD_DATA = d2_ascii;
            6'd37: LCD_DATA = d1_ascii;
            6'd38: LCD_DATA = d0_ascii;
            default: begin LCD_RS = 1'b0; LCD_DATA = 8'h80; end
        endcase
    end

endmodule

module de2_115_top (
    input  wire          CLOCK_50,
    input  wire [0:0]    KEY,
    input  wire [17:0]   SW,
    output wire [17:0]   LEDR,
    output wire [6:0]    HEX0,
    output wire [6:0]    HEX1,
    output wire [6:0]    HEX2,
    output wire [6:0]    HEX3,
    output wire [6:0]    HEX4,
    output wire [6:0]    HEX5,
    output wire [6:0]    HEX6,
    output wire [6:0]    HEX7,
    output wire          LCD_ON,
    output wire          LCD_BLON,
    output wire          LCD_RW,
    output wire          LCD_EN,
    output wire          LCD_RS,
    output wire [7:0]    LCD_DATA,
    output wire          UART_TXD,
    input  wire          UART_RXD
);
    de2_115_wrapper u_wrapper (
        .CLOCK_50 (CLOCK_50),
        .KEY      (KEY),
        .SW       (SW),
        .LEDR     (LEDR),
        .HEX0     (HEX0),
        .HEX1     (HEX1),
        .HEX2     (HEX2),
        .HEX3     (HEX3),
        .HEX4     (HEX4),
        .HEX5     (HEX5),
        .HEX6     (HEX6),
        .HEX7     (HEX7),
        .LCD_ON   (LCD_ON),
        .LCD_BLON (LCD_BLON),
        .LCD_RW   (LCD_RW),
        .LCD_EN   (LCD_EN),
        .LCD_RS   (LCD_RS),
        .LCD_DATA (LCD_DATA),
        .UART_TXD (UART_TXD),
        .UART_RXD (UART_RXD)
    );
endmodule
