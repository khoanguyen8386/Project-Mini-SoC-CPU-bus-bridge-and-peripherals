'`timescale 1ns/1ps
module apb_clk_ctrl(
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,
    output wire clk_en_gpio,
    output wire clk_en_timer,
    output wire clk_en_uart
);
    reg [2:0] clk_en_reg;
    wire apb_write = SEL && PENABLE && PWRITE;
    wire apb_read = PSEL && !PWRITE; 
    
    //offset 0x00: CLK_EN_REG
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            clk_en_reg <= 3'b111;
        end else if (apb_write && (PADDR[7:0]== 8'h00)) begin
            clk_en_reg <= PWDATA[2:0];
        end
    end
    always @(*) begin
        if(apb_read && (PADDR[7:0] == 8'h00)) begin
            PRDATA = {29'h0, clk_en_reg};
        end else begin
            PRDATA = 32'h0000_0000;
        end
    end

    assign PREADY = 1'b1;
    assign clk_en_gpio = clk_en_reg[0];
    assign clk_en_timer = clk_eh_reg[1];
    assign clk_en_uart = clk_en_reg[2];

endmodule