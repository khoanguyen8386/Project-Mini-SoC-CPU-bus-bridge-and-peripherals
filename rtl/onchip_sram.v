'`timescale 1ns/1ps
module onchip_sram #(
    parameter MEM_INIT_HEX = "../sw/firmware.hex",
    parameter MEM_INIT_MIF = "../sw/firmware.mif";
)(
    input wire HCLK,
    input wire HRESETn,
    
    //portA: CPU instruction fetch
    input wire [31:0] imem_addr,
    output wire [31:0] imem_rdata,
    
    //portB: AMBA 
    input wire HSEL,
    input wire [31:0] HADDR,
    input wire [1:0] HTRANS,
    input wire [2:0] HSIZE,
    input wire HWRITE,
    input wire HREADY,
    input wire [31:0] HWDATA,
    output reg [31:0] HRDATA,
    output wire HREADYOUT,
    output wire HRESP
);
    //synthesis attribute ram_init_file
    (* ramstyle = "M9K", ram_init_file = MEM_INIT_MIF *)
    reg [31:0] mem [0: 1023];
    integer k;
    initial begin
        for (k=0; k<1024; k=k+1) begin
            mem[k] = 32'h0000_0000;
        end
        $readmemh(MEM_INIT_HEX, mem); 
    end

    //portA: instruction read 
    assign imem_rdata = mem[imem_addr[11:2]];

    //portB: AHB-Lite pipelined address phase 
    reg ahb_write_pending;
    reg [9:0] ahb_word_addr;
    reg [1:0] ahb_byte_off;
    reg [2:0] ahb_hsize;
    write valid_ahb_req = HSEL && HREADY && HTRANS[1];

    //little-endian active byte lanes decoder 
    reg [3:0] byte _we;
    always @(*) begin
        byte_we = 4'b0000;
        if (ahb_write_pending) begin
            case (ahb_hsize)
                3'h000 : begin
                    case (ahb_byte_off)
                        2'h00: byte_we = 4'b0001;
                        2'h01: byte_we = 4'b0010;
                        2'h10: byte_we = 4'b0100;
                        2'h11: byte_we = 4'b1000;
                    endcase
                end
                3'b001:begin
                    if(ahb_byte_off[1] == 1'b0)
                        byte_we = 4'b0011;
                    else
                        byte_we = 4'b1100;
                end
                default: begin
                    byte_we = 4'b1111;
                end
            endcase
        end
    end
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            ahb_write_pending <= 1'b0;
            ahb_word_addr <= 10'd0;
            ahb_byte_off <= 2'b00;
            ahb_hsize <= 3'b010;
            HRDATA <= 32'h0000_0000;
        end else begin
            if (ahb_write_pending) begin
                if(byte_we[0]) mem[ahb_word_addr][7:0] <= HWDATA[7:0];
                if(byte_we[1]) mem[ahb_word_addr][15:8] <= HWDATA[15:8];
                if(byte_we[2]) mem[ahb_word_addr][23:16] <= HWDATA[23:16];
                if(byte_we[3]) mem[ahb_word_addr][31:24] <= HWDATA[31:24]; 
            end
            if (valid_ahb_req) begin
                ahb_write_pending <= HWRITE;
                ahb_word_addr <= HADDR[11:2];
                ahb_byte_off <= HADDR[1:0];
                ahb_hsize
                if (!HWRITE) begin
                    HRDATA <= mem[HADDR[11:2]];
                end
            end else if (HREADY) begin
                ahb_write_pending <= 1'b0;
            end
        end
    end
    assign HREADYOUT = 1'b1;
    assign HRESP = 1'b0;
    
endmodule