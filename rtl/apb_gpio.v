'`timescale 1ns/1ps
module apb_gpip(
    input wire PCLK,
    input wire PRESETn,
    input wire clk_en_gpio,

    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,
    //DE2-155 board pins
    input wire [17:0] sw_in,
    output wire [17:0] ledr_out
);
    reg [17:0] sw_sync1;
    reg [17:0] sw_sync2;
    reg [17:0] ledr_reg;
    reg [17:0] dir_reg;
    wire apb_write = PSEL && PENABLE && PWRITE;
    wire apb_read = PSEL && !PWRITE;

    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            sw_sync1 <= 18'h00000;
            sw_sync2 <= 18'h00000;
            ledr_reg <= 18'h00000;
            dir_reg <= 18'h3FFFF;
        end else if (clk_en_gpio) begin
            sw_sync1 <= sw_in;
            sw_sync2 <= sw_sync1;
            if(apb_write) begin
                case (PADDR[7:0])
                    8'h04: ledr_reg <= PWDATA[17:0];
                    8'h08: dir_reg <= PWDATA[17:0];
                    default: ;
                endcase 
            end
        end
    end
    always @(*) begin
        PRDATA = 32'h0000_0000;
        if(apb_read) begin
            case (PADRR[7:0])
                8'h00: PRDATA = {14'h0, sw_sync2};
                8'h04: PRDATA = {14'h0, ledr_reg};
                8'h08: PRDATA = {14'h0, dir_reg}; 
                default: PRDATA = 32'h0000_0000;
            endcase
        end
    end
    assign PREADY = 1'b1;
    assign ledr_out = ledr_reg & dir_reg;
endmodule