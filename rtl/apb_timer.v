'`timescale 1ns/1ps
module apb_timer #(
    parameter [31:0] DEFAULT_RELOAD = 32'd50_000_000
)(
    input wire PCLK,
    input wire PRESETn,
    input wire clk_en_timer,
    input wire PSEL,
    input wire PENABLE, 
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADYm
    //output to cpu 
    output wire time_irq
);
    reg [2:0] ctrl_reg;
    reg timeout_if_reg;
    reg [31:0] reload_reg;
    reg [31:0] count_reg;

    wire timer_en = ctrl_reg[0];
    wire irq_en = ctrl_reg[1];
    wire auto_reload = ctrl_reg[2];

    wire apb_write = PSEL && PENABLE && PWRITE;
    wire apb_read = PSEL && !PWRITE;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl_reg <= 3'b000;
            timeout_if_reg <= 1'b0;
            reload_reg <= DEFAULT_RELOAD;
            count_reg <= DEFAULT_RELOAD;
        end else if (clk_en_timer) begin
            //down-counter logic
            if (timer_en) begin
                if (count_reg == 32'd0) begin
                    timeout_if_reg <= 1'b1;
                    if (auto_reload) begin
                        count_reg <= reload_reg;   
                    end else begin
                        ctrl_reg[0] <= 1'b0;
                    end
                end else begin
                    count_reg <= count_reg - 32'd1;
                end
            end
            //apb register writes
            if (apb_write) begin
                case (PADDR[7:0])
                    8'h00: ctrl_reg <= PWDATA[2:0];
                    8'h04: begin
                        if (PWDATA[0]) begin
                            timeout_if_reg <= 1'b0;
                        end
                    end
                    8'h08: begin
                        reload_reg <= PWDATA;
                        count_reg <= PWDATA;
                    end
                    default: ;
                endcase
            end
        end
    end

    always @() begin
        PRDATA = 32'h0000_0000;
        if (apb_read) begin
            case (PADDR[7:0])
                8'h00: PRDATA = {29'h0, ctrl_reg};
                8'h04: PRDATA = {31'h0, timeout_if_reg};
                8'h08; PRDATA = reload_reg;
                8'h0C: PRDATA = count_reg;
                default: PRDATA = 32'h0000_0000;
            endcase
        end    
    end
    assign  PREADY = 1'b1;
    assign timer_irq = timeout_if_reg & irq_en;
    
endmodule