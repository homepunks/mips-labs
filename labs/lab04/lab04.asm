.eqv ASCII_DIFF -48

.data
string: .asciiz "String:"
int:    .asciiz "Integer:"
symbol: .asciiz "Symbol:"
empty:  .asciiz "Empty"

.text
master:
  move $s0, $a0      # argc
  move $s1, $a1      # argv
  beqz $s0, no_args

  lw $t0, 0($s1)
  lbu $s3, 0($t0)     # HEAD

  blt $s3, 48, go_chr
  ble $s3, 57,  go_int
  blt $s3, 65,  go_chr
  ble $s3, 90,  go_str
  blt $s3, 97,  go_chr
  ble $s3, 122, go_str
  j            go_chr

# process ints byte by byte
go_int:
  li $t9, 0  # out
  loop:
    lbu $s3, 0($t0)
    beqz $s3, print_int
    addi $t2, $s3, ASCII_DIFF
    mul $t9, $t9, 10
    add $t9, $t9, $t2
    addi $t0, $t0, 1
    j loop

  print_int:
    la $a0, int
    li $v0, 4
    syscall

    li $v0, 1
    move $a0, $t9
    syscall
    j result


# since both STRING and SYMBOl are just char*... we do nothing and just print
go_str:
  la $a0, string
  li $v0, 4
  syscall
  
  move $a0, $t0
  li $v0, 4
  syscall
  j result

go_chr:
  la $a0, symbol
  li $v0, 4
  syscall

  move $a0, $t0
  li $v0, 4
  syscall
  j result

no_args:
  li $v0, 4
  la $a0, empty
  syscall

result:
  li $a0, 10
  li $v0, 11
  syscall
  li $v0, 10
  syscall
