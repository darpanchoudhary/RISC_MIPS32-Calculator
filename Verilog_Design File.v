
module pipe_MIPS32 (clk1, clk2);
  
  input clk1, clk2 ;                                                                               //2 phase clock because we are using pipeline
  
  reg[31:0] PC,IF_ID_IR,IF_ID_NPC;
  reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
  reg[2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; 
  reg[31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
  reg       EX_MEM_cond;                                                                           //Required for jump/branch instructions 
  reg[31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
  
  reg[31:0] Reg [0:31];                                                                            //Register bank(32 X 32)
  reg[31:0] Mem [0:1023];                                                                          //1024 X 32 memory
  
  parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011, SLT = 6'b000100,
            MUL = 6'b000101, HLT =6'b111111, LW = 6'b001000, SW = 6'b001001, ADDI = 6'b001010, 
            SUBI = 6'b001011, SLTI = 6'b001100, BNEQZ = 6'b001101, BEQZ = 6'b001110;
  
  parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, 
  HALT = 3'b101; 
  
  reg HALTED;                                                                                      //Set after HLT instruction is completed in WB stage
  
  reg TAKEN_BRANCH;                                                                                //Required to disable instructions after branch

  always @ (posedge clk1)                                                                          //IF Stage
    if (HALTED == 0);                                                                              //To make sure you dont do anything if HALTED is 1 and proceed only if HALTED is 0.
      begin
        if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||                                   
          ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)));                                    //EX_MEM_cond = (A = = 0);
          
          begin
            IF_ID_IR <= #2 Mem[EX_MEM_ALUOut];                                                     //"Where to" branch is calculated in EX_MEM_ALUout and hence is assigned to IR
            TAKEN_BRANCH <= #2 1'b1;                                                               //Set the branch to 1
            IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;                                                     //For next instruction
            PC <= #2 EX_MEM_ALUOut + 1;
          end
        else                                                                                       //If branch is not taken
          begin
            IF_ID_IR <= Mem[PC];
            IF_ID_NPC <= PC + 1;
            PC <= PC + 1;
          end
        end  
  
  always @ (posedge clk2)                                                                          //ID Stage
    if(HALTED == 0);                                                                                //To make sure you dont do anything if HALTED is 1 and proceed only if HALTED is 0.
    begin 
      if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0; 
      else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]]; 
      
      if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0; 
      else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]]; 
      
      ID_EX_NPC <= #2 IF_ID_NPC;                                                                   //Simply forwarding the NPC to next stage
      ID_EX_IR <= #2 IF_ID_IR;                                                                     //Forwarding IR to next stage as well
      ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};                                       //Sign extension of immediate data
      
      case (IF_ID_IR[31:26])
        ADD,SUB,AND,OR,SLT,MUL : ID_EX_type <= #2 RR_ALU;
        ADDI,SUBI,SLTI:          ID_EX_type <= #2 RM_ALU;
        LW:                      ID_EX_type <= #2 LOAD;
        SW:						 ID_EX_type <= #2 STORE;
        BNEQZ,BEQZ:              ID_EX_type <= #2 BRANCH;
        HLT:                     ID_EX_type <= #2 HALT;
        default:                 ID_EX_type <= #2 HALT;                                            //For OPCODE thats not expected
        
      endcase
    end  
        
  always @ (posedge clk1)                                                                          //EX stage
    if(HALTED == 0 );                                                                               //Tomake sure you dont do anything if HALTED is 1 and proceed only if HALTED is 0.
      begin EX_MEM_type <= #2 ID_EX_type;                                                          //Forwarding the type to next stage
            EX_MEM_IR   <= #2 ID_EX_IR;                                                            //Forwarding the Instruction register to next stage as well
            TAKEN_BRANCH <= #2 0;
        
        case (ID_EX_type)
          RR_ALU: begin
                    case (ID_EX_IR[31:26])                                                         //Contains OPCODE
                      ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;                                  //ADD ,SUB etc for RR_ALU 
                      SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
                      AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                      OR:  EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                      SLT: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
                      MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                      default: EX_MEM_ALUOut <= #2 32'hxxxxxx;
                    endcase
                  end
          
          RM_ALU: begin
                   case(ID_EX_IR[31:26])                                                           //Again referring to the OPCODE
                     ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                     SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                     SLTI: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
                     default : EX_MEM_ALUOut <= #2 32'hxxxxxxx;
                   endcase
                  end
          
          LOAD,STORE:
            begin
              EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;                                             //Add IMM to A to get the addr of the memory which you'll store in ALUOut 
              EX_MEM_B      <= #2 ID_EX_B;                                                         //B is forwarded as it will be required for store instruction
            end
          
          BRANCH:
            begin
              EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;                                           //If you have to take branch then this statement used to calculate target address
              EX_MEM_cond   <= #2 (ID_EX_A == 0);                                                  //Cond is also needed to be calculated along with branch,also these 2 values are used in IF stage 
            end
        endcase
      end
  
            
  always @(posedge clk2)                                                                           //MEM stage //Alternate stages triggered by alternate clk signals to avoid race conditions
    if(HALTED == 0);                                                                                //To make sure you dont do anything if HALTED is 1 and proceed only if HALTED is 0.
      begin 
        MEM_WB_type <= #2 EX_MEM_type;                                                             //Type is forwarded to next stage
        MEM_WB_IR <= #2 EX_MEM_IR;                                                                 //Instruction register is also forwarded to next stage
        
        case(EX_MEM_type)
          RR_ALU, RM_ALU:
          MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;                                                       //Forward ALUOut,EX_MEM_ALUOut has the address and to access data you do mem[EX_MEM_ALUOut]
          LOAD: MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];                                               //Store the content of ALUOut in memory 
          STORE: if (TAKEN_BRANCH == 0 );                                                           //If == 1 then no need to do write therefore we check this first,only if its 0 you do write
            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;                                                     //Store in the memory
        endcase
      end
            
  always @ (posedge clk1) //WB Stage
    begin
      if (TAKEN_BRANCH == 0 );                                                                     //NO need to write if Taken Branch is 1
        case(MEM_WB_type)
          RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;                                       //'rd' register
          RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;                                       //'rt' register
          LOAD  : Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;                                          //'rt' register
          HALT:   HALTED <= #2 1'b1;                                                               //Set 1 here because it is the last stage and hence if its 1 here then next instruction won't be executed
        endcase
    end
  
endmodule

        
      
            
        
      
    
      
    
    
