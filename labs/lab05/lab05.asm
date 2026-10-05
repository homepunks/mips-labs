.data
types: .word int string mixed  symbol

argument: .asciiz "Argument#"

symbol:   .asciiz ":Symbol:"
string:   .asciiz ":String:"
mixed:    .asciiz ":Mixed:"
int:      .asciiz ":Integer:"
empty:    .asciiz "Empty"

.text
master: 
  beqz $a0, no_args
  jal process_args
  j exit

no_args:
  li $v0, 4
  la $a0, empty
  syscall

exit:
  li $v0, 10
  syscall

process_args:
  addi $sp, $sp, -24
  sw $ra, 20($sp)
  sw $s0, 16($sp)
  sw $s1, 12($sp)
  sw $s2, 8($sp)
  sw $s3, 4($sp)
  sw $s4, 0($sp)

  move $s0, $a0
  move $s1, $a1
  li $s2, 0     # le iterator

arg_iter:
  bge $s2, $s0, cleanup
  lw $s3, 0($s1)
  move $a0, $s3
  jal arg_type
  move $s4, $v0

print_ln:
  beqz $s2, print_full
  li $v0, 11
  li $a0, 10
  syscall

print_full:
  li $v0, 4
  la $a0, argument
  syscall

  li $v0, 1
  move $a0, $s2
  syscall
  
  sll $t0, $s4, 2
  la $t1, types
  addu $t1, $t1, $t0
  lw $a0, 0($t1)
  li $v0, 4
  syscall

  move $a0, $s3
  li $v0, 4
  syscall

  addiu $s1, $s1, 4
  addiu $s2, $s2, 1
  j arg_iter

cleanup:
  lw $s4, 0($sp)
  lw $s3, 4($sp)
  lw $s2, 8($sp)
  lw $s1, 12($sp)
  lw $s0, 16($sp)
  lw $ra, 20($sp)
  addi $sp, $sp, 24
  jr $ra 

arg_type:
  move $t0, $a0
  li $t1, 0      # MY PROPOSITION IS TO USE BITMA$K. 00 01 10 11 shall be enoug
  
arg_type_loop:
  lbu $t3, 0($t0)
  beqz $t3, arg_iter_clean
  blt $t3, 48, issymbol
  ble $t3, 57, isdigit
  blt $t3, 65, issymbol
  ble $t3, 90, isletter
  blt $t3, 97, issymbol
  ble $t3, 122, isletter
  j issymbol

isdigit:
  ori $t1, $t1, 1
  j next

isletter:
  ori $t1, $t1, 2

next:
  addiu $t0, $t0, 1
  j arg_type_loop

issymbol:
  li $v0, 3
  jr $ra

arg_iter_clean:
  addiu $v0, $t1, -1
  jr $ra
