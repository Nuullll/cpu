    addi $a0, $zero, 3 	# a0 = 0 + 3
    jal sum			# jump to Label: 'sum'
Loop:
    beq $zero, $zero, Loop	# if (0 == 0) jump to Label: 'Loop'
sum:
    addi $sp, $sp, -8		# sp -= 8
    sw $ra, 4($sp)			# sp[1] = ra
    sw $a0, 0($sp)			# sp[0] = a0
    slti $t0, $a0, 1			# t0 = (a0 < 1) ? 1 : 0
    beq $t0, $zero, L1		# if (t0 == 0) jump to Label: 'L1'
    xor $v0, $zero, $zero	# v0 = 0 ^ 0 = 0
    addi $sp, $sp, 8			# sp += 8
    jr $ra					# jump to Register: $ra
L1:
    addi $a0, $a0, -1		# a0 -= 1
    jal sum				# jump and link Label: 'sum'
    lw $a0, 0($sp)			# a0 = sp[0]
    lw $ra, 4($sp)			# ra = sp[1]
    addi $sp, $sp, 8			# sp += 8
    add $v0, $a0, $v0		# v0 += a0
    jr $ra					# jump to Register: $ra