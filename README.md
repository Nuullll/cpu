# 数字逻辑与处理器基础大作业

## 单周期处理器

### 设计要求

完成一个单周期处理的控制器部分。达到实现`MIPS`指令集的一个子集，包括：

```
lw, sw, lui
add, addu, sub, subu, addi, addiu
and, or, xor, nor, andi, sll, srl, sra, slt, sltu, sltiu
beq, j, jal, jr, jalr
```

### 处理器结构

![structure](structure.png)

1. 回答以下问题

    1. 由`RegDst`信号控制的多路选择器，输入2对应常数31。这里的31代表31号寄存器`$ra`，在执行以下跳转指令时`RegDst`信号会置为2，因为跳转指令需保存跳转前的地址，便于在执行完子过程后恢复至原来的位置。
        ```
        jal target
        ```
    
    2. 由`ALUSrc1`信号控制的多路选择器，输入1对应的指令`[10-6]`是移位运算的位移量，在执行以下三种移位指令时`ALUSrc1`信号会置为1，ALU从指令`[10-6]`段读取位移量再进行计算。
        ```
        sll rd, rt, shamt
        srl rd, rt, shamt
        sra rd, rt, shamt
        ```
    
    3. 由`MemtoReg`信号控制的多路选择器，输入2对应的是`PC+4`，执行以下跳转指令时`MemtoReg`信号会置为2，将`PC+4`存入寄存器便于以后恢复。
        ```
        jal target
        jalr rd, rs
        ```
    
    4. 图中的处理器结构并没有`Jump`控制信号，取而代之的是`PCSrc`信号。`PCSrc`信号控制的多路选择器，输入2对应的是从寄存器读取的地址，并赋给`PC`，执行以下两种寄存器跳转指令时`PCSrc`信号会置为2，跳转至寄存器中的地址。
        ```
        jr rs
        jalr rd, rs
        ```
    
    5. 利用`ExtOp`信号区分指令`[15:0]`是有符号型立即数还是无符号型立即数。
        ```
        # ExtOp = 1
        lui rt, imm
        slti rt, rs, imm
        
        # ExtOp = 0
        sltiu rt, rs, imm
        ```
        
    6. 指令全为0时，当前处理器结构下等价于
        ```
        sll $zero, $zero, 0
        ```
       即空指令功能，故无需更改处理器结构。
    
2. 根据对各控制信号功能的理解，得如下真值表

![truetable1](truetable_1.png)

![truetable2](truetable_2.png)


### 完成控制器

1. 阅读`CPU.v`，理解其实现方式。

    ```verilog
    
    module CPU(reset, clk);
	    input reset, clk;
	
	    reg [31:0] PC;
	    wire [31:0] PC_next;
	    always @(posedge reset or posedge clk)
		    if (reset)
			    PC <= 32'h00000000;
		    else
			    PC <= PC_next;
	
	    wire [31:0] PC_plus_4;
	    assign PC_plus_4 = PC + 32'd4;
	
	    wire [31:0] Instruction;
	    InstructionMemory instruction_memory1(.Address(PC), 
	                                          .Instruction(Instruction));
	
	    wire [1:0] RegDst;
	    wire [1:0] PCSrc;
	    wire Branch;
	    wire MemRead;
	    wire [1:0] MemtoReg;
	    wire [3:0] ALUOp;
	    wire ExtOp;
	    wire LuOp;
	    wire MemWrite;
	    wire ALUSrc1;
	    wire ALUSrc2;
	    wire RegWrite;
	
	    Control control1(
		    .OpCode(Instruction[31:26]), .Funct(Instruction[5:0]),
		    .PCSrc(PCSrc), .Branch(Branch), .RegWrite(RegWrite), .RegDst(RegDst), 
		    .MemRead(MemRead),	.MemWrite(MemWrite), .MemtoReg(MemtoReg),
		    .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .ExtOp(ExtOp), 
		    .LuOp(LuOp),	.ALUOp(ALUOp));
	
	    wire [31:0] Databus1, Databus2, Databus3;
	    wire [4:0] Write_register;
	    assign Write_register = (RegDst == 2'b00)? Instruction[20:16]: 
	                            (RegDst == 2'b01)? Instruction[15:11]: 5'b11111;
	    RegisterFile register_file1(.reset(reset), .clk(clk), .RegWrite(RegWrite), 
		    .Read_register1(Instruction[25:21]), 
		    .Read_register2(Instruction[20:16]), .Write_register(Write_register),
		    .Write_data(Databus3), .Read_data1(Databus1), .Read_data2(Databus2));
	
	    wire [31:0] Ext_out;
	    assign Ext_out = {ExtOp? {16{Instruction[15]}}: 
	                      16'h0000, Instruction[15:0]};
	
	    wire [31:0] LU_out;
	    assign LU_out = LuOp? {Instruction[15:0], 16'h0000}: Ext_out;
	
	    wire [4:0] ALUCtl;
	    wire Sign;
	    ALUControl alu_control1(.ALUOp(ALUOp), .Funct(Instruction[5:0]), 
	                            .ALUCtl(ALUCtl), .Sign(Sign));
	
	    wire [31:0] ALU_in1;
	    wire [31:0] ALU_in2;
	    wire [31:0] ALU_out;
	    wire Zero;
	    assign ALU_in1 = ALUSrc1? {17'h00000, Instruction[10:6]}: Databus1;
	    assign ALU_in2 = ALUSrc2? LU_out: Databus2;
	    ALU alu1(.in1(ALU_in1), .in2(ALU_in2), .ALUCtl(ALUCtl),
	             .Sign(Sign), .out(ALU_out), .zero(Zero));
	
	    wire [31:0] Read_data;
	    DataMemory data_memory1(.reset(reset), .clk(clk), .Address(ALU_out), 
	                            .Write_data(Databus2), .Read_data(Read_data), 
	                            .MemRead(MemRead), .MemWrite(MemWrite));
	    assign Databus3 = (MemtoReg == 2'b00)? ALU_out: 
	                      (MemtoReg == 2'b01)? Read_data: PC_plus_4;
	
	    wire [31:0] Jump_target;
	    assign Jump_target = {PC_plus_4[31:28], Instruction[25:0], 2'b00};
	
	    wire [31:0] Branch_target;
	    assign Branch_target = (Branch & Zero)? PC_plus_4 + {LU_out[29:0], 2'b00}: 
	                           PC_plus_4;
	
	    assign PC_next = (PCSrc == 2'b00)? Branch_target: 
	                     (PCSrc == 2'b01)? Jump_target: Databus1;

    endmodule
	
    ```
	
2. 完成`Control.v`

    ```verilog
        
    module Control(OpCode, Funct,
	    PCSrc, Branch, RegWrite, RegDst, 
	    MemRead, MemWrite, MemtoReg, 
	    ALUSrc1, ALUSrc2, ExtOp, LuOp, ALUOp);
	    input [5:0] OpCode;
	    input [5:0] Funct;
	    output [1:0] PCSrc;
	    output Branch;
	    output RegWrite;
	    output [1:0] RegDst;
	    output MemRead;
	    output MemWrite;
	    output [1:0] MemtoReg;
	    output ALUSrc1;
	    output ALUSrc2;
	    output ExtOp;
	    output LuOp;
	    output [3:0] ALUOp;
	
	    // Your code below

	    assign PCSrc = 
		    (OpCode == 6'h02 || OpCode == 6'h03)? 2'b01:
		    (OpCode == 6'h00 && (Funct == 6'h08 || Funct == 6'h09))? 2'b10:
		    2'b00;

	    assign Branch = (OpCode == 6'h04)? 1: 0;

	    assign RegWrite = 
		    (OpCode == 6'h2b || OpCode == 6'h04 || OpCode == 6'h02
			    || (OpCode == 6'h00 && Funct == 6'h08))? 0: 1;

	    assign RegDst = 
		    (OpCode == 6'h03)? 2'b10:
		    (OpCode == 6'h23 || OpCode == 6'h0f || OpCode == 6'h08
			    || OpCode == 6'h09 || OpCode == 6'h0c || OpCode == 6'h0a
			    || OpCode == 6'h0b)? 2'b01: 
		    2'b00;

	    assign MemRead = (OpCode == 6'h23)? 1: 0;

	    assign MemWrite = (OpCode == 6'h2b)? 1: 0;

	    assign MemtoReg = 
		    (OpCode == 6'h03 || (OpCode == 6'h00 && Funct == 6'h09))? 2'b10:
		    (OpCode == 6'h23)? 2'b01:
		    2'b00;

	    assign ALUSrc1 = 
		    (OpCode == 6'h00 && (Funct == 6'h00 || Funct == 6'h02 
			    || Funct == 6'h03))? 1: 0;

	    assign ALUSrc2 = 
		    (OpCode == 6'h23 || OpCode == 6'h2b || OpCode == 6'h0f
			    || OpCode == 6'h08 || OpCode == 6'h09 || OpCode == 6'h0c
			    || OpCode == 6'h0a || OpCode == 6'h0b)? 1: 0;

	    assign ExtOp = (OpCode == 6'h0b)? 0: 1;

	    assign LuOp = (OpCode == 6'h0f)? 1: 0;
	
	    // Your code above
	
	    assign ALUOp[2:0] = 
		    (OpCode == 6'h00)? 3'b010: 
		    (OpCode == 6'h04)? 3'b001: 
		    (OpCode == 6'h0c)? 3'b100: 
		    (OpCode == 6'h0a || OpCode == 6'h0b)? 3'b101: 
		    3'b000;
		
	    assign ALUOp[3] = OpCode[0];
	
    endmodule
    
    ```
    
    
    
    
    
    
    
