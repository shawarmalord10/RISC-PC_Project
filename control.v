module ctrlunit( 
input [3:0] opcode,
output reg [2:0] ALUctrl, 
output reg  EnRW, ALUsrc, MReg, MR, MW, 
input clk 
); 
     
    always@(*) begin 
        if (opcode== 4'b0001) begin //lw
            ALUctrl= 3'b010; //add  
            EnRW=1'b1; 
            ALUsrc= 1'b1;
            MReg= 1'b0;
            MR= 1'b1;
            MW= 1'b0;
            end 
            
        else if (opcode == 4'b0000) begin // ADD
            ALUctrl = 3'b010;   //add
            EnRW = 1'b1;
            ALUsrc = 1'b0;      
            MReg = 1'b1;   
            MR = 1'b0;
            MW = 1'b0;
            end      
            
        else if (opcode== 4'b0010) begin //sw
            ALUctrl=3'b010;  //add
            EnRW=1'b0;
            ALUsrc= 1'b1; 
            MReg= 1'b1;
            MR= 1'b0;
            MW= 1'b1;
          
            end 
        else if (opcode== 4'b0011) begin //subi
            MR= 1'b0;
            MW= 1'b0;
            ALUsrc= 1'b1;
            MReg= 1'b1;
            ALUctrl= 3'b110; //sub 
            EnRW=1'b1; 
            end
        else if (opcode== 4'b0111) begin //or
            MR= 1'b0;
            MW= 1'b0;
            ALUsrc= 1'b0;
            MReg= 1'b1;
            ALUctrl= 3'b001; //or
             EnRW=1'b1;
            end
        else if (opcode== 4'b1111) begin //nor
            MReg= 1'b1;
            MR= 1'b0;
            MW= 1'b0;
            ALUsrc= 1'b0;
            ALUctrl= 3'b011; //nor 
            EnRW=1'b1;
            end     
    end 
  
endmodule