# ret = b * c
# ret = ret / d
# ret = a + ret
# ret = ret - e
# ret = ret + 1

.data
prompt_a: .asciiz "Enter a: "
prompt_b: .asciiz "Enter b: "
prompt_c: .asciiz "Enter c: "
prompt_d: .asciiz "Enter d: "
prompt_e: .asciiz "Enter e: "
result:   .asciiz "Result: "


.text
  li $v0, 4
  la $a0, prompt_a
  syscall

  li $v0, 5
  syscall
  move $t0, $v0

  li $v0, 4
  la $a0, prompt_b
  syscall

  li $v0, 5
  syscall
  move $t1, $v0

  li $v0, 4
  la $a0, prompt_c
  syscall

  li $v0, 5
  syscall
  move $t2, $v0

  li $v0, 4
  la $a0, prompt_d
  syscall

  li $v0, 5
  syscall
  move $t3, $v0

  li $v0, 4
  la $a0, prompt_e
  syscall

  li $v0, 5
  syscall
  move $t4, $v0

  mul $s0, $t1, $t2
  div $s0, $t3
  mflo $s0
  add $s0, $s0, $t0
  sub $s0, $s0, $t4
  addi $s0, $s0, 1

  li $v0, 4
  la $a0, result
  syscall

  li $v0, 1
  move $a0, $s0
  syscall

  li $v0, 10
  syscall
