`timescale 1ns/1ps

module cpu_core_mips (
    input wire clk,
    input wire rst_n,
    
    // instruction memory port 
    output reg [31:0] imem_addr, 
    input wire [31:0] imem_rdata,
    
    // data memory/ bus wrapper interface
    output wire mem_reg,
    output wire mem_we,
    output wire [2:0] mem_size,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    input wire cpu_stall,
    
    //hardware interrupt input (from APB timer)
    input wire time_irq,

    //debug for output
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_epc,
    output wire dbg_in_isr
);
    //instruction field
    wire [5:0] opcode = imem_rdata[31:26];
    wire [4:0] rs = imem_rdata[25:21];
    wire [4:0] rt = imem_rdata[20:16];
    wire [4:0] rd = imem_rdata[15:11];
    wire [4:0] shamt = imem_rdata[10:6];
    wire [5:0] funct = imem_rdata[5:0];
    wire [15:0] imm16 = imem_rdata[15:0];
    wire [25:0] jaddr = imem_rdata[25:0];

    wire [31:0] sign_ext_imm ={{16{imm16[15]}}, imm16};
    wire [31:0] zero_ext_imm = {16'h0000, imm16};
    wire [31:0] upper_imm = {imm16, 16'h0000};

    //opcode & decode
    localparam OP_RTYPE = 6'b000000;
    localparam OP_J = 6'b000010;
    localparam OP_JAL = 6'b000011;
    localparam OP_BEQ = 6'b000100;
    localparam OP_BNE = 6'b000101;
    localparam OP_ADDI = 6'b001000;
    localparam OP_ADDIU = 6'b001001;
    localparam OP_SLTI = 6'b001010;
    localparam OP_ANDI = 6'b001100;
    localparam OP_ORI = 6'b001101;
    localparam OP_XORI = 6'b001110;
    localparam OP_LUI = 6'b001111; 
    localparam OP_COP0 = 6'010000;
    localparam OP_LW = 6'b100011;
    localparam OP_SW = 6'b101011;

    localparam FN_SLL = 6'b000000;
    localparam FN_SRL = 6'b000010;
    localparam FN_JR = 6'b001000;
    localparam FN_ADD = 6'b100000;
    localparam FN_ADDU = 6'b100001;
    localparam FN_SUB = 6'b100010;
    localparam FN_SUBU = 6'b100011;
    localparam FN_AND = 6'b100100;
    localparam FN_OR = 6'b100101;
    localparam FN_XOR = 6'b100110;
    localparam FN_NOR = 6'b100111;
    localparam FN_SLT = 6'b101010;
    localparam FN_ERET = 6'b011000;

    wire is_rtype = (opcode == OP_RTYPE);
    wire is_jr = is_rtype && (funct == FN_JR);
    wire is_eret = (opcode == OP_COP0) && (funct == FN_ERET);
    wire is_lw = (opcode == OP_LW);
    wire is_sw = (opcode == OP_SW);
    wire is_beq = (opcode == OP_BEQ);
    wire is_bne = (opcode == OP_BNE);
    wire is_j = (opcode == OP_J);
    wire is_jal = (opcode == OP_JAL);
    
    // 32 x 32-bit general purpose register file
    reg [31:0] regfile [0:31];
    integer i;
    wire [31:0] rdata1 = (rs == 5'd0) ? 32'h0000_0000 : regfile[rs];
    wire [31:0] rdata2 = (rt == 5'd0) ? 32'h0000_0000 : regfile[rt];

    //alu & control logic
    reg [31:0] alu_b;
    reg [31:0] alu_out;
    reg reg_write_en;
    reg [4:0] reg_waddr;
    reg [31:0] reg_wdata;

    always @(*) begin 
        //operand B selection
        case (opcode)
            OP_RTYPE,
            OP_BEQ,
            OP_BNE: alu_b = rdata2;
            OP_ANDI,
            OP_ORI,
            OP_XORI: alu_b = zero_ext_imm;
            OP_LUI: alu_b = upper_imm;
            default: alu_b = sign_ext_imm;
        endcase
        
        //alu computation 
        case (opcode)
            OP_RTYPE: begin 
                case (funct)
                    FN_SLL: alu_out = rdata2 << shamt;
                    FN_SRL: alu_out = rdata2 >> shamt;
                    FN_ADD,
                    FN_ADDU: alu_out = rdata1 + rdata2;
                    FN_SUB,
                    FN_SUBU: alu_out = rdata1 - rdata2;
                    FN_AND: alu_out = rdata1 & rdata2;
                    FN_OR: alu_out = rdata1 | rdata2;
                    FN_XOR: alu_out = rdata1 ^ rdata2;
                    FN_NOR: alu_out = ~(rdata1 | rdata2);
                    FN_SLT: alu_out = ($signed(rdata1) < $signed(rdata2)) ? 32'd1 : 32'd0;
                    default: alu_out = 32'h0000_0000;
                endcase
            end
            OP_ADDI,
            OP_ADDIU,
            OP_LW,
            OP_SW: alu_out = rdata1 + rdata_b;
            OP_SLTI: alu_out = ($signed(rdata1) < $signed(alu_b)) ? 32'd1 : 32'd0;
            OP_ANDI: alu_out = rdata1 & alu_b;
            OP_ORI: alu_out = rdata1 | alu_b;
            OP_XORI: alu_out = rdata1 ^ alu_b;
            OP_LUI: alu_out = alu_b;
            default: alu_out = 32'h0000_0000;
        endcase

        //register write-back control 
        reg_write_en = 1'b0;
        reg_waddr = rd;
        reg_wdata = alu_out;
        if(is_rtype) begin 
            if(funct != FN_JR) begin 
                reg_write_en = 1'b1;
                reg_waddr = rd;
                reg_wdata = alu_out;
            end
        end else if (opcode == OP_ADDI || opcode == OP_ADDIU ||
                     opcode == OP_SLTI || opcode == OP_ANDI ||
                     opcode == OP_ORI || opcode == OP_XORI ||
                     opcode == OP_LUI) begin
                        reg_write_en = 1'b1;
                        reg_waddr = rt;
                        reg_wdata = alu_out;
                     end else if (is_lw) begin
                        reg_write_en = 1'b1;
                        reg_waddr = rt;
                        reg_wdata = mem_data;
                     end else if (is_lw) begin 
                        reg_write_en = 1'b1;
                        reg_waddr = rt;
                        reg_wdata = mem_rdata;
                     end else if (is_jal) begin 
                        reg_write_en = 1'b1;
                        reg_waddr = 5'd31;
                        reg_wdata = imem_addr + 32'd4;
                     end
    end