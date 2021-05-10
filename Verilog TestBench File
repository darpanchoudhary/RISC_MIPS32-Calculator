
//In order to test the Verilog Design, load instructions in the memory and initiate the program counter to 0
//Goal of this testbench is to add R1 and R2 ,add R3 and R4


module test_mips32;
  
  reg clk1,clk2;
  integer k;
  
  pipe_MIPS32 mips(clk1, clk2);
  
  initial
    begin
      clk1 = 0;
      clk2 = 0;
      repeat(20)                                                                    //Generating 2 phase clock.20 clk cycles should be sufficient
        begin
          #5 clk1 = 1; #5 clk1 = 0 ;
          #5 clk2 = 1; #5 clk2 = 0;                                                 //We are using BLOCKING ASSIGNMENTs to make sure we get 2 clocks in different phase
        end
    end
  
  initial
    begin
      for(k=0; k<31; k++)
        mips.Reg[k] = k;
      
      mips.Mem[0] = 32'h2801000a;                                                   //ADDI R1,R0,10 -- basically writing 10 into R1 register
      mips.Mem[1] = 32'h28020014;                                                   //ADDI R2,R0,20 -- basically writing 20 into R2 register
      mips.Mem[2] = 32'h28030019;                                                   //ADDI R3,R0,25 -- basically writing 25 into R3 register
      mips.Mem[3] = 32'h0ce77800;                                                   //OR  R7,R7,R7 -- dummy instruction to ensure delay in the pipeline
      mips.Mem[4] = 32'h0ce77800;                                                   //OR  R7,R7,R7 -- dummy instruction to ensure delay in the pipeline
      mips.Mem[5] = 32'h00222000;                                                   //ADD R4,R1,R2
      mips.Mem[6] = 32'h0ce77800;                                                   //OR  R7,R7,R7 -- dummy instruction
      mips.Mem[7] = 32'h00832800;                                                   //ADD R5,R4,R3 
      mips.Mem[8] = 32'hfc000000;                                                   //HLT
      mips.HALTED = 0;
      mips.PC = 0;
      mips.TAKEN_BRANCH = 0;
      
      #280
      for (k=0; k<6; k++)
        $display ("R%1d - %2d", k, mips.Reg[k]); //displaying R,register number and -%2d is for value  of the corresponding register
    end
  
  initial
    begin
      $dumpfile ("mips.vcd");
      $dumpvars(0, test_mips32);
      #300 $finish;
    end

endmodule
