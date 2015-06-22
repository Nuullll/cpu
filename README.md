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
    
    2. 由`ALUSrc1`信号控制的多路选择器，输入1对应的指令[10-6]是移位运算的位移量，在执行以下三种移位指令时`ALUSrc1`信号会置为1，ALU从指令[10-6]段读取位移量再进行计算。
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
    
    5. 利用`ExtOp`信号区分指令[15:0]是有符号型立即数还是无符号型立即数。
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
    
    
    
    
    
    
    
    
    
