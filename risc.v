`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2025 17:15:42
// Design Name: 
// Module Name: risc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module risc(input clk

    );
    wire jmp,bne,be,mem_rd,mem_wr,alu_sel,r_sel,r_wr;
    wire [1:0] wb_sel,alu_m;
    wire [5:0]opcode;
    data_path dp(
    .clk(clk),
    .jmp(jmp),
    .be(be),
    .bne(bne),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .alu_sel(alu_sel),
    .r_sel(r_sel),
    .wb_sel(wb_sel),
    .r_wr(r_wr),
    .alu_m(alu_m),
    .opcode(opcode)
    ); 
    
    control_unit cu(
    .opcode(opcode),
    .r_sel(r_sel),
    .wb_sel(wb_sel),
    .alu_m(alu_m),
    .jmp(jmp),
    .be(be),
    .bne(bne),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .alu_sel(alu_sel),
    .r_wr(r_wr)
    );
      
        
endmodule

module data_path (
    input clk,
    input jmp,
    input be,
    input bne,
    input mem_rd,
    input mem_wr,
    input alu_sel,
    input r_sel,
    input [1:0] wb_sel,
    input r_wr,
    input [1:0] alu_m,
    output [5:0] opcode
);

    reg [15:0] pc;
    wire [15:0] pc_next;
    wire [15:0] pc2;
    wire [31:0] instr;
    wire [4:0] reg_write_dest;
    wire [15:0] reg_write_data;
    wire [4:0] reg_read_addr_1;
    wire [4:0] reg_read_addr_2;
    wire [15:0] reg_read_data_1;
    wire [15:0] reg_read_data_2;
    wire [15:0] alu_input2;
    wire [3:0] ALU_Control;
    wire [15:0] ALU_out;
    wire zero_flag;
    wire [15:0] jump_shift;
    wire [15:0] mem_read_data;

    
    initial begin
    pc <= 16'd0;
    end


    always @(posedge clk) pc <= pc_next;


    assign pc2 = pc + 16'd1;

    Instruction_Memory im (
        .pc(pc),
        .instr(instr),
        .clk(clk)
    );

    assign opcode = instr[31:26];

    assign reg_write_dest = (r_sel==1)?instr[25:21]:instr[20:16];
    assign reg_read_addr_1 = ((opcode >= 6'h04) && (opcode <= 6'h0C)) ? instr[20:16] : instr[25:21];
    assign reg_read_addr_2 = ((opcode >= 6'h04) && (opcode <= 6'h0C)) ? instr[15:11] : instr[20:16];

    GPRs reg_file (
        .clk(clk),
        .reg_write_en(r_wr),
        .reg_write_dest(reg_write_dest),
        .reg_write_data(reg_write_data),
        .reg_read_addr_1(reg_read_addr_1),
        .reg_read_data_1(reg_read_data_1),
        .reg_read_addr_2(reg_read_addr_2),
        .reg_read_data_2(reg_read_data_2),
        .wb_sel(wb_sel)
    );

    alu_control ACU (
        .alu_m(alu_m),
        .opcode(instr[31:26]),
        .alu_cnt(ALU_Control)
    );

    assign alu_input2 = (alu_sel == 1'b1) ? instr[15:0] : reg_read_data_2;

    ALU au (
        .op1(reg_read_data_1),
        .op2(alu_input2),
        .alu_cnt(ALU_Control),
        .result(ALU_out),
        .zero(zero_flag)
    );

    Data_Memory dm (
        .clk(clk),
        .mem_access_addr(ALU_out),
        .mem_write_data(reg_read_data_1),
        .mem_write_en(mem_wr),
        .mem_read(mem_rd),
        .mem_read_data(mem_read_data)
    );

    // Branch logic
    wire [15:0] pc_be   = pc2 + instr[15:0];
    wire [15:0] pc_bne  = pc2 + instr[15:0];
    wire be_control     = be & zero_flag;
    wire bne_control    = bne & ~zero_flag;

    wire [15:0] pc_2be  = (be_control) ? pc_be : pc2;
    wire [15:0] pc_2bne = (bne_control) ? pc_bne : pc_2be;
    wire [15:0] pc_j    =  instr[25:10]; // or pc-relative if needed

   assign pc_next = (jmp==1'b1) ? pc_j : pc_2bne;

    // Write-back data
    assign reg_write_data = (wb_sel == 2'b00) ? ALU_out :
                            (wb_sel == 2'b01) ? mem_read_data :
                            (wb_sel == 2'b10) ? reg_read_data_2 :
                            instr[20:5];

endmodule

module control_unit (
    input [5:0] opcode,
    output reg r_sel,
    output reg [1:0] wb_sel,
    output reg [1:0] alu_m,
    output reg jmp,
    output reg be,
    output reg bne,
    output reg mem_rd,
    output reg mem_wr,
    output reg alu_sel,
    output reg r_wr
);
    always @(*)
    begin
    case(opcode)
    6'b000000:
        begin
        r_sel = 1'b0;
        alu_sel = 1'b1;
        wb_sel = 2'b01;
        r_wr = 1'b1;
        mem_rd = 1'b1;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b10;
        jmp = 1'b0;
        end
        
    6'b000001:
        begin
        r_sel = 1'b0;
        alu_sel = 1'b1;
        wb_sel = 2'b00;
        r_wr = 1'b0;
        mem_rd = 1'b0;
        mem_wr = 1'b1;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b10;
        jmp = 1'b0;
        end
        
    6'b000010:
        begin
        r_sel = 1'b1;
        alu_sel = 1'b0;
        wb_sel = 2'b10;
        r_wr = 1'b1;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b10;
        jmp = 1'b0;
        end
        
    6'b000011:
        begin
        r_sel = 1'b1;
        alu_sel = 1'b0;
        wb_sel = 2'b11;
        r_wr = 1'b1;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b10;
        jmp = 1'b0;
        end 
        
    6'b000100,6'b000101,6'b000110,6'b000111,6'b001000,6'b001001,6'b001010,6'b001011,6'b001100:
        begin
        r_sel = 1'b1;
        alu_sel = 1'b0;
        wb_sel = 2'b00;
        r_wr = 1'b1;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b00;
        jmp = 1'b0;
        end
        
    6'b001101:
        begin
        r_sel = 1'b0;
        alu_sel = 1'b0;
        wb_sel = 2'b00;
        r_wr = 1'b0;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b1;
        bne = 1'b0;
        alu_m = 2'b01;
        jmp = 1'b0;
        end
        
    6'b001110:
        begin
        r_sel = 1'b0;
        alu_sel = 1'b0;
        wb_sel = 2'b00;
        r_wr = 1'b0;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b1;
        alu_m = 2'b01;
        jmp = 1'b0;
        end
        
    6'b001111:
        begin
        r_sel = 1'b0;
        alu_sel = 1'b0;
        wb_sel = 2'b00;
        r_wr = 1'b0;
        mem_rd = 1'b0;
        mem_wr = 1'b0;
        be = 1'b0;
        bne = 1'b0;
        alu_m = 2'b00;
        jmp = 1'b1;
        end
        default: begin
        r_sel = 0;
        wb_sel = 0;
        alu_m = 0; 
        jmp = 0; 
        be = 0; 
        bne = 0;
        mem_rd = 0; 
        mem_wr = 0; 
        alu_sel = 0; 
        r_wr = 0;
        end

    endcase
    end        
        
                               
endmodule

module GPRs (
    input clk,
    input reg_write_en,
    input [4:0] reg_write_dest,
    input [15:0] reg_write_data,
    input [4:0] reg_read_addr_1,
    output [15:0] reg_read_data_1,
    input [4:0] reg_read_addr_2,
    output [15:0] reg_read_data_2,
    input [1:0] wb_sel
);
    
    reg [15:0] registers [0:31];
    
    assign reg_read_data_1 = registers[reg_read_addr_1];
    assign reg_read_data_2 = registers[reg_read_addr_2];
    
    integer i;

    always @(posedge clk) begin      
       if (reg_write_en)
            registers[reg_write_dest] <= reg_write_data;
    end
endmodule

module Data_Memory (
    input clk,
    input [15:0] mem_access_addr,
    input [15:0] mem_write_data,
    input mem_write_en,
    input mem_read,
    output reg [15:0] mem_read_data
);
    reg [15:0] memory [0:65535];

    always @(posedge clk) begin
        if (mem_write_en)
            memory[mem_access_addr[15:0]] <= mem_write_data;
    end

    always @(*) begin
        if (mem_read)
            mem_read_data = memory[mem_access_addr[15:0]];
        else
            mem_read_data = 16'h0000;
    end
endmodule

module alu_control (
    input [1:0] alu_m,
    input[5:0] opcode,
    output reg[3:0] alu_cnt
);

    wire[7:0] alu_control_in = {alu_m,opcode};
    
    always @(*)begin
    casex (alu_control_in)
        8'b11xxxxxx: alu_cnt = 4'b1001;
        8'b10xxxxxx: alu_cnt = 4'b0000;
        8'b01xxxxxx: alu_cnt = 4'b0001;
        8'b00000100: alu_cnt = 4'b0000;
        8'b00000101: alu_cnt = 4'b0001;
        8'b00000110: alu_cnt = 4'b0010;
        8'b00000111: alu_cnt = 4'b0011;
        8'b00001000: alu_cnt = 4'b0100;
        8'b00001001: alu_cnt = 4'b0101;
        8'b00001010: alu_cnt = 4'b0110;
        8'b00001011: alu_cnt = 4'b0111;
        8'b00001100: alu_cnt = 4'b1000;
        default: alu_cnt = 4'b0000;
        endcase
    end     
       
endmodule

module ALU(
 input  [15:0] op1,  
 input  [15:0] op2,  
 input  [3:0] alu_cnt, 
 
 output reg [15:0] result,   
 output zero
    );

always @(*)
begin 
 case(alu_cnt)
 4'b0000: result = op1 + op2; 
 4'b0001: result = op1 - op2; 
 4'b0010: result = ~op1;
 4'b0011: result = op1<<op2;
 4'b0100: result = op1>>op2;
 4'b0101: result = op1 & op2; 
 4'b0110: result = op1 | op2;
 4'b0111: result = op1 ^ op2; 
 4'b1000: result = (op1>op2)?16'd1:16'd0;
 4'b1001:result = 16'd0;
 default:result = op1 + op2; 
 endcase
end
assign zero = (result==16'd0) ? 1'b1: 1'b0;
 
endmodule

module Instruction_Memory(
    input [15:0] pc,                  
    output wire [31:0] instr,
    input clk         
);

    reg [31:0] imemory [0:65535];      

    wire [15:0] rom_addr = pc;     

    initial begin
        $readmemb("C:/Users/Pranav/Desktop/test.prog", imemory, 0, 65535);  
    end

    assign instr = imemory[pc];

endmodule
                                                         