`timescale 1ns / 1ps

module top( 
); 
    reg [4:0]PC; 
    reg clk; 
    reg rest;
    initial begin 
        clk = 0; 
        PC=0; 
    end 
    always begin 
        #5 clk = ~clk; 
    end 
 
// IF_ID reg
reg [31:0] IF_ID_IR; 
reg [4:0] IF_ID_NPC; 
 

//ID_EX reg
reg [4:0] ID_EX_NPC;
reg [31:0] ID_EX_A,ID_EX_B, ID_EX_IR;
reg [31:0] ID_EX_IMM;
reg [3:0] ID_EX_RD, ID_EX_RS, ID_EX_RT;
reg [2:0] ID_EX_ALUctrl; 
reg ID_EX_RegWrite;
reg ID_EX_MemtoReg;
reg ID_EX_MemRead, ID_EX_MemWrite;
reg ID_EX_ALUsrc;

// EX_MEM reg
reg [31:0] EX_MEM_IR, EX_MEM_ALUout, EX_MEM_B; 
reg [3:0] EX_MEM_RD;
reg EX_MEM_MemtoReg;  
reg EX_MEM_RegWrite;
reg EX_MEM_MemRead, EX_MEM_MemWrite;  
 
//MEM_WB reg
reg [3:0] MEM_WB_RD;
reg [31:0] MEM_WB_ALUout;
reg [31:0] MEM_WB_IR;
reg [31:0] MEM_WB_DATA;
reg MEM_WB_RegWrite;
reg MEM_WB_MemtoReg; 
 
//wires 
wire [31:0] instr, nxt_instr, rd1,rd2, extnd_imm; 
wire [4:0] NPC;
wire [31:0] reg_wd, data_rd;
wire [15:0] imm;
wire [3:0] opcode;
wire [3:0] rs,rt,rd, dst;
wire [31:0] mux1_out; 
wire [31:0] ALUout; 
wire zero, EnRW, ALUsrc, MReg, MR; 
wire [2:0]ALUctrl;
wire [1:0] FA,FB; 
wire [31:0] forwardA_mux_out, forwardB_mux_out;
wire PCWrite, IFIDWrite, ST;

//IF blocks_______________________________________________________________
PC_adder nextpc(.pc_in(PC), .npc(NPC)); 

imem instr_mem( .addr(PC), .instr(instr), .EnIM(PCWrite));

imem next_instr( .addr(NPC), .instr(nxt_instr));  

//ID blocks_______________________________________________________________
sgn_extnd sgn_extnd(.imm(imm), .extnd_imm(extnd_imm));
 
regfile reg_file(.clk(clk),.rn1(rs), .rn2(rt), .wn(MEM_WB_RD),  
    .wd(reg_wd), .EnRW(MEM_WB_RegWrite), .rd1(rd1), .rd2(rd2));  

ctrlunit ctrl_call(.opcode(opcode), .ALUctrl(ALUctrl), 
     .EnRW(EnRW), .ALUsrc(ALUsrc),
     .MReg(MReg), .MR(MR), .MW(MW));

//EX blocks_______________________________________________________________
MUX_alusrc m1(.ALUsrc(ID_EX_ALUsrc), .b(forwardB_mux_out), .extnd_imm(ID_EX_IMM), .in2(mux1_out));

assign forwardA_mux_out = 
    (FA == 2'b10) ? EX_MEM_ALUout : 
    (FA == 2'b01) ? reg_wd :  
    ID_EX_A;
    
assign forwardB_mux_out = 
    (FB == 2'b10) ? EX_MEM_ALUout : 
    (FB == 2'b01) ? reg_wd :
    ID_EX_B;
    
alu alu_call(.in1(forwardA_mux_out), .in2(mux1_out),  
    .ALUctrl(ID_EX_ALUctrl), .result(ALUout), .zero(zero) ); 
  
 
//MEM blocks_______________________________________________________________   
data_mem data_mem( .memread(EX_MEM_MemRead), .memwrite(EX_MEM_MemWrite),
        .addr(EX_MEM_ALUout), .wd(EX_MEM_B), .rd(data_rd), .clk(clk));

//WB blocks_______________________________________________________________
MUX_wb m3(.MemtoReg(MEM_WB_MemtoReg), .data_out(MEM_WB_DATA), .ALUout(MEM_WB_ALUout), .reg_wd(reg_wd));

//hazard detection_______________________________________________________________
hazard_detection hdu( .ID_EX_MemRead(ID_EX_MemRead), .ID_EX_RD(ID_EX_RD), .IF_ID_RS(rs),
    .IF_ID_RT(rt), .PCWrite(PCWrite), .IFIDWrite(IFIDWrite), .ST(ST) );

data_forwarding forwarding(.EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_RegWrite(MEM_WB_RegWrite),
    .EX_MEM_RD(EX_MEM_RD), .EX_MEM_MemRead(EX_MEM_MemRead), .MEM_WB_RD(MEM_WB_RD), 
    .ID_EX_RS(ID_EX_RS), .ID_EX_RT(ID_EX_RT),
    .FA(FA), .FB(FB) );

//stage update
always@(posedge clk) begin //IF 
    if(PCWrite) begin
        IF_ID_IR<= instr;
        IF_ID_NPC<= NPC; 
        PC<= NPC; 
        end
    end 

//instruction Decoding Logic
assign opcode= IF_ID_IR[31:28]; 
assign rd= IF_ID_IR[27:24]; 
assign rs= IF_ID_IR[23:20]; 
assign rt= IF_ID_IR[19:16]; 
assign imm = IF_ID_IR[15:0];
 
always@(posedge clk) begin //ID    
    ID_EX_RS<= rs;
    ID_EX_RT<= rt;
    ID_EX_A<=rd1; //read data1
    ID_EX_B<=rd2; //read data2
    ID_EX_IMM<= extnd_imm;
    ID_EX_IR<= IF_ID_IR;
    ID_EX_NPC<= IF_ID_NPC; 
    ID_EX_RD<= rd; //dest. addr.
    
    if (ST) begin
        ID_EX_RegWrite<= 1'b0;
        ID_EX_MemWrite<= 1'b0;
        ID_EX_MemRead<= 1'b0;  
        ID_EX_ALUsrc<= 1'b0;
        ID_EX_ALUctrl <= 3'b000;  
        ID_EX_MemtoReg <= 1'b0;
        end
    else begin
        ID_EX_RegWrite<= EnRW;
        ID_EX_MemWrite<= MW;
        ID_EX_MemRead<= MR;  
        ID_EX_ALUsrc<= ALUsrc;
        ID_EX_MemtoReg<= MReg;
        ID_EX_ALUctrl<= ALUctrl;
        end 
    end
 
always@(posedge clk) begin //EX 
    EX_MEM_ALUout<=ALUout;
    EX_MEM_B<= ID_EX_B;
    EX_MEM_IR<= ID_EX_IR;
    EX_MEM_RD<= ID_EX_RD; 
    
    EX_MEM_RegWrite <= ID_EX_RegWrite;
    EX_MEM_MemtoReg<= ID_EX_MemtoReg;
    EX_MEM_MemRead<= ID_EX_MemRead;
    EX_MEM_MemWrite<= ID_EX_MemWrite;
    end 
    
always@(posedge clk) begin //MEM 
    MEM_WB_RD<= EX_MEM_RD;
    MEM_WB_ALUout<= EX_MEM_ALUout;
    MEM_WB_DATA<= data_rd;
    
    MEM_WB_RegWrite<= EX_MEM_RegWrite;
    MEM_WB_MemtoReg<= EX_MEM_MemtoReg;
    end 
   
endmodule
