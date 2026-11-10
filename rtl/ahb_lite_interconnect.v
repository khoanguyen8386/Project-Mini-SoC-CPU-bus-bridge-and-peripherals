'`timescale 1ns/1ps
module ahb_lite_interconnect(

    input wire HCLK;
    input wire HRESETn,
    
    //Input signal 
    input wire [31:0] HADDR,
    input wire [1:0] HTRANS,

    //decoder seclect output
    output reg HSEL_SRAM,
    output reg HSEL_APB,
    output reg HSEL_DEF,

    //SRAM
    input wire [31:0] HRDATA_SRAM,
    input wire HREADYOUT_SRAM,
    input wire HRESP_SRAM,

    //APB Bridge
    input wire [31:0] HRDATA_APB,
    input wire HREADYOUT_APB,
    input wire HRESP_APB,

    //Response output
    output reg [31:0] HRDATA,
    output reg HREADY,
    output reg HRESP
);
    always @(*) begin 
        HSEL_SRAM = 1'b0;
        HSEL_APB = 1'b0;
        HSEL_DEF = 1'b0;
        if (HADDR[31:12] == 20'h00000) begin 
            HSEL_SRAM = 1'b1;
        end else if (HADDR[31:14] == 18'h10000) begin 
            HSEL_APB = 1'b1;
        end else begin 
            HSEL_DEF = 1'b1;
        end 
    end 
    
    localparam DEF_IDLE = 1'b0;
    localparam DEF_ERR2 = 1'b1;

    reg def_state;
    reg HREADYOUT_DEF;
    reg HRESP_DEF;

    wire def_valid_trans = HSEL_DEF && HREADY && HTRANS[1];

    always @(posedge HCLK or negedge HRESETn) begin 
        if(!HRESETn) begin 
            def_state <= DEF_IDLE;
            HREADYOUT_DEF <= 1'b1;
            HRESP_DEF <= 1'b0;
        end else begin 
            case (def_state)
                DEF_IDLE: begin
                    if (def_valid_trans) begin 
                        def_state <= DEF_ERR2;
                        HREADYOUT_DEF <= 1'b0;
                        HRESP_DEF <= 1'b1;
                    end else begin 
                        HREADYOUT_DEF <= 1'b1;
                        HRESP_DEF <= 1'b0;
                    end 
                end 
                DEF_ERR2: begin
                    def_state <= DEF_IDLE;
                    HREADYOUT_DEF <= 1'b1;
                    HRESP_DEF <= 1'b1;
                end 
            endcase
        end 
    end

    localparam [1:0] MUX_SRAM = 2'b00;
    localparam [1:0] MUX_APB = 2'b01;
    localparam [1:0] MUX_DEF = 2'b10;

    reg[1:0] hsel_data_phase;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_data_phase <= MUX_SRAM;
        end else if (HREADY) begin
            if (HSEL_SRAM)
                hsel_data_phase <= MUX_SRAM;
            else if (HSEL_APB)
                hsel_data_phase <= MUX_APB;
            else
                hsel_data_phase <= MUX_DEF;
        end
    end
    always @(*) begin
        case (hsel_data_phase)      
            MUX_SRAM: begin
                HDATA = HRDATA_SRAM;
                HREADY = HREADYOUT_SRAM;
                HRESP = HRESP_SRAM;
            end 
            MUX_APB: begin
                HRDATA = HRDATA_APB;
                HREADY = HREADYOUT_APB;
                HRESP = HRESP_APB;
            end
            default: begin
                HRDATA = 32'h0000_0000;
                HREADY = HREADYOUT_DEF;
                HRESP = HRESP_DEF;
            end
        endcase
    end
endmodule