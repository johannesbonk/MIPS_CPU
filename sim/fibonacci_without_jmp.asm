.text 

addi $t0, $0, 8 # max i of fibonacci
addi $t1, $0, 1 # $t0 == current fib, init to 1
slt $t2, $0, $0 # prev fib init to 0 
slt $t3, $0, $0 # prevprev fib init to 0 
slt $t4, $0, $0 # init counter i to 0
addi $t5, $0, 10000000 # wait count init
sw $t5, 0x2004

fib:  
addi $t5, $t5, -1
slt $t6, $t5, $0
beq $t6, $0, fib
add $0, $0, $0 

lw $t5, 0x2004

addi $t4, $t4, 1 # increase counter 
beq $t4, $t0, wait_forever
add $t3, $0, $t2 # prevprev fib = prev fib
add $t2, $0, $t1    # prev fib = cur fib 
add $t1, $t2, $t3   # cur fib = prevprev fib + prev fib 
beq $0, $0, fib
sw $t1, 0x2000


wait_forever: 
beq $0, $0, wait_forever
