`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2025 01:17:03
// Design Name: 
// Module Name: hazard_unit
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


module hazard_detection(
    input ID_EX_MemRead,
    input [3:0] ID_EX_RD,
    input [3:0] IF_ID_RS,
    input [3:0] IF_ID_RT,
    output reg PCWrite,
    output reg IFIDWrite,
    output reg ST
);

    initial begin
        PCWrite = 1'b1;
        IFIDWrite = 1'b1;
        ST = 1'b0;
    end
    
    always @(*) begin
        PCWrite = 1'b1;
        IFIDWrite = 1'b1;
        ST = 1'b0;
        
        if (ID_EX_MemRead && ((ID_EX_RD == IF_ID_RS) || (ID_EX_RD == IF_ID_RT))) begin
            PCWrite = 1'b0;     //for stalling PC
            IFIDWrite = 1'b0;   //for stalling IF/ID
            ST = 1'b1;          //bubble
        end
    end
endmodule

module data_forwarding(
    input EX_MEM_RegWrite, MEM_WB_RegWrite,
    input EX_MEM_MemRead,
    input [3:0] EX_MEM_RD,
    input [3:0] MEM_WB_RD,
    input [3:0] ID_EX_RS, ID_EX_RT,
    output reg [1:0] FA,FB
);
    always @(*) begin
        // Forwarding for RS (FA)
        if (EX_MEM_RegWrite && !EX_MEM_MemRead && (EX_MEM_RD == ID_EX_RS)) 
            FA = 2'b10; // Forward EX/MEM ALU result (but NOT for load instr)
        else if (MEM_WB_RegWrite && (MEM_WB_RD == ID_EX_RS)) 
            FA = 2'b01; // Forward MEM/WB data
        else 
            FA = 2'b00;

        // Forwarding for RT (FB) - Similar logic
        if (EX_MEM_RegWrite && !EX_MEM_MemRead && (EX_MEM_RD == ID_EX_RT)) 
            FB = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_RD == ID_EX_RT)) 
            FB = 2'b01;
        else 
            FB = 2'b00;
    end
endmodule


