`timescale 1ns / 1ps

module PC_adder(
input [4:0] pc_in,
output [4:0] npc
);
    assign npc= pc_in + 4;
endmodule

module imem( 
input EnIM,
input [4:0] addr, 
output reg [31:0] instr, 
input clk 
); 
 
    reg [7:0] inst_mem[31:0]; 
     
    initial begin 
        {inst_mem[0],inst_mem[1],inst_mem[2],inst_mem[3]} = 32'h0123_0000; 
        {inst_mem[4],inst_mem[5],inst_mem[6],inst_mem[7]} = 32'h1410_0007; 
        {inst_mem[8],inst_mem[9],inst_mem[10],inst_mem[11]} = 32'h3540_1234; 
        {inst_mem[12],inst_mem[13],inst_mem[14],inst_mem[15]} = 32'h7876_0000;  
        {inst_mem[16],inst_mem[17],inst_mem[18],inst_mem[19]} = 32'hFA98_0000;
    end 
    always @(*) begin
        if (EnIM)
            instr = {inst_mem[addr], inst_mem[addr+1], inst_mem[addr+2], inst_mem[addr+3]};
        else
            instr = 32'h0; //Output NOP when disabled
    end
endmodule 

module sgn_extnd(
input [15:0] imm,
output [31:0] extnd_imm
);
    assign extnd_imm = { {16{imm[15]}}, imm };
endmodule

module regfile( 
input [3:0] rn1, rn2, wn, 
input [31:0] wd, 
input  EnRW,wb, 
output [31:0] rd1, rd2, 
input clk 
); 
    reg [31:0] register[31:0]; 
     
    initial begin 
        register[2] = 32'h9; 
        register[3] = 32'h10; 
        register[6] = 32'h688CA; 
        register[7] = 32'h964EA;
        register[9] = 32'h1212E;
        
    end 
     
    assign 
 
        rd1= register[rn1], 
        rd2= register[rn2]; 
     
    always@(negedge clk) begin 
        if (EnRW == 1'b1) begin 
        register[wn]<= wd; 
        end 
    end 
endmodule 

module MUX_alusrc(
input [31:0] b,extnd_imm,
input ALUsrc,
output [31:0] in2
);
    assign in2 = ALUsrc ? extnd_imm : b;
endmodule

module alu( 
input [31:0] in1, in2, 
input [2:0] ALUctrl, 
output reg [31:0] result, 
output zero 
); 
    assign zero = (result == 0); 
    always @(*) begin 
        case(ALUctrl) 
        3'b000: result = (in1 & in2); 
        3'b001: result = (in1 | in2); 
        3'b010: result = in1 + in2;
        3'b011: result = ~(in1 | in2);
        3'b110: result = in1 - in2; 
        3'b111: result = (in1 < in2) ? 32'h1 : 32'h0; 
        default: result = 0; 
        endcase 
    end 
endmodule


module data_mem( 
input [31:0] addr, 
input [31:0] wd, 
input memread,memwrite, 
output reg [31:0] rd, 
input clk 
); 
    reg [7:0] data_mem [128:0];
    initial begin
        {data_mem[32], data_mem[33], data_mem[34], data_mem[35]} = 32'h12345678;
        {data_mem[26], data_mem[27], data_mem[28], data_mem[29]} = 32'h12345678;
        {data_mem[20], data_mem[21], data_mem[22], data_mem[23]} = 32'h12345678;
    end
     
    always @(*) begin 
        if (memread) begin 
            rd = {data_mem[addr], data_mem[addr + 1], data_mem[addr + 2], data_mem[addr + 3]}; 
        end
        else begin
            rd = 32'h0;
        end
    end
    
    //Sequential write
    always @(posedge clk) begin 
        if (memwrite) begin 
            data_mem[addr] <= wd[31:24]; 
            data_mem[addr+1] <= wd[23:16]; 
            data_mem[addr+2] <= wd[15:8]; 
            data_mem[addr+3] <= wd[7:0]; 
        end 
    end 
endmodule

module MUX_wb(
input MemtoReg,
input [31:0] data_out, ALUout,
output [31:0] reg_wd
);
    assign reg_wd = MemtoReg ? ALUout:data_out;
endmodule
