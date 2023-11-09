.text 

addi $t0, $0, 8 # max i of fibonacci
addi $t1, $0, 1 # $t0 == current fib, init to 1
slt $t2, $0, $0 # prev fib init to 0 
slt $t3, $0, $0 # prevprev fib init to 0 
fib2:
slt $t4, $0, $0 # init counter i to 0
fib:  
addi $t4, $t4, 1 # increase counter 
beq $t4, $t0, wait_forever
add $t3, $0, $t2 # prevprev fib = prev fib
add $t2, $0, $t1    # prev fib = cur fib 
add $t1, $t2, $t3   # cur fib = prevprev fib + prev fib 
beq $0, $0, fib
sw $t1, 0x2000
j fib


wait_forever: 
j wait_forever
