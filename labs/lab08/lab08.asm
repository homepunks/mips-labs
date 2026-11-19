.eqv TEXT_CAP 32768
.eqv DIMS_CAP 127
.eqv MAX_DIM 32
.eqv CHUNK 1024

.macro close_fd(%reg)
  move $a0, %reg
  li $v0, 16
  syscall
.end_macro

.data
dims_name: .asciiz "dimensions.txt"
a_name: .asciiz "matrixA.txt"
b_name: .asciiz "matrixB.txt"
result_name: .asciiz "result.txt"

done_txt: .asciiz "Done: result.txt written.\n"
dims_io_txt: .asciiz "Error: cannot open/read dimensions.txt\n"
dims_big_txt: .asciiz "Error: dimensions.txt is too large\n"
dims_bad_txt: .asciiz "Error: dimensions must be two integers in 1..32\n"
a_fail_txt: .asciiz "Error: cannot read/parse matrixA.txt\n"
b_fail_txt: .asciiz "Error: cannot read/parse matrixB.txt\n"
res_fail_txt: .asciiz "Error: cannot write result.txt\n"

space_char: .byte 32
newline_char: .byte 10
probe_b: .space 1
  .align 3
number_buffer: .space 32
text_buffer: .space 32769

.text
# $s2  $s3 $s4 are the ABC 
master:
  li $t0, -8
  and $sp, $sp, $t0

  la $a0, dims_name
  la $a1, text_buffer
  li $a2, DIMS_CAP
  jal read_text_file
  li $t0, -2
  beq $v0, $t0, dims_too_big
  bltz $v0, dims_cant_read

  la $a0, text_buffer
  jal parse_uint
  beqz $v1, dims_bad
  move $s0, $v0
  move $a0, $v1
  jal parse_uint
  beqz $v1, dims_bad
  move $s1, $v0

  blt $s0, 1, dims_bad
  bgt $s0, MAX_DIM, dims_bad
  blt $s1, 1, dims_bad
  bgt $s1, MAX_DIM, dims_bad
  mul $s5, $s0, $s1

  move $a0, $s0
  move $a1, $s1
  jal alloc_matrix
  move $s2, $v0
  move $a0, $s0
  move $a1, $s1
  jal alloc_matrix
  move $s3, $v0
  move $a0, $s0
  move $a1, $s1
  jal alloc_matrix
  move $s4, $v0

  la $a0, a_name
  move $a1, $s2
  move $a2, $s5
  la $a3, text_buffer
  jal load_matrix
  bnez $v0, a_load_fail

  la $a0, b_name
  move $a1, $s3
  move $a2, $s5
  la $a3, text_buffer
  jal load_matrix
  bnez $v0, b_load_fail

  move $a0, $s2
  move $a1, $s3
  move $a2, $s4
  move $a3, $s5
  jal add_matrices

  la $a0, result_name
  move $a1, $s4
  move $a2, $s0
  move $a3, $s1
  jal write_matrix
  bnez $v0, result_fail

  la $a0, done_txt
  j finish

dims_cant_read:
  la $a0, dims_io_txt
  j finish
dims_too_big:
  la $a0, dims_big_txt
  j finish
dims_bad:
  la $a0, dims_bad_txt
  j finish
a_load_fail:
  la $a0, a_fail_txt
  j finish
b_load_fail:
  la $a0, b_fail_txt
  j finish
result_fail:
  la $a0, res_fail_txt

finish:
  li $v0, 4
  syscall
  li $v0, 10
  syscall

# read whole file in chunks and nul after wards
# return bytes and ec's : -1 on io error, -2 if file doesnt fit
# $s0 buffer, $s1 used, $s2 capacity, $s3 fd
read_text_file:
  addiu $sp, $sp, -16
  sw $s0, 12($sp)
  sw $s1, 8($sp)
  sw $s2, 4($sp)
  sw $s3, 0($sp)
  move $s0, $a1
  move $s2, $a2

  li $a1, 0
  li $v0, 13
  syscall
  bltz $v0, read_open_fail
  move $s3, $v0
  move $s1, $zero

# read chunks till eof and catch if buf is full
read_loop:
  bne $s1, $s2, read_chunk
  move $a0, $s3
  la $a1, probe_b
  li $a2, 1
  li $v0, 14
  syscall
  bltz $v0, read_io_fail
  bgtz $v0, read_too_big
  j read_eof

read_chunk:
  subu $a2, $s2, $s1
  li $t0, CHUNK
  bleu $a2, $t0, read_request
  move $a2, $t0



read_request:
  move $a0, $s3
  addu $a1, $s0, $s1
  li $v0, 14
  syscall
  bltz $v0, read_io_fail
  beqz $v0, read_eof
  addu $s1, $s1, $v0
  j read_loop

read_eof:
  addu $t0, $s0, $s1
  sb $zero, 0($t0)
  close_fd($s3)
  move $v0, $s1
  j read_cleanup

read_io_fail:
  close_fd($s3)
  li $v0, -1
  j read_cleanup

read_too_big:
  close_fd($s3)
  li $v0, -2
  j read_cleanup

read_open_fail:
  li $v0, -1

read_cleanup:
  lw $s0, 12($sp)
  lw $s1, 8($sp)
  lw $s2, 4($sp)
  lw $s3, 0($sp)
  addiu $sp, $sp, 16
  jr $ra

# $a0 rows, $a1 cols <=> $v0 aligned base and ask sbrk for 8N + 7 so we can round up to 8 and still have 8N bytes
alloc_matrix:
  mul $t0, $a0, $a1  # N
  sll $a0, $t0, 3     # 8 bytes per double
  addiu $a0, $a0, 7
  li $v0, 9
  syscall
  addiu $t1, $v0, 7
  li $t2, -8
  and $v0, $t1, $t2   # (raw + 7) & ~7
  jr $ra

# $a0 filename, $a1 base, $a2 N, $a3 text buf
# read  file and parse n doubles into base (/w 0 and -1 as ec's)
# $s0 dest ptr, $s1 left, $s2 text cursor
load_matrix:
  addiu $sp, $sp, -16
  sw $ra, 12($sp)
  sw $s0, 8($sp)
  sw $s1, 4($sp)
  sw $s2, 0($sp)
  move $s0, $a1
  move $s1, $a2
  move $s2, $a3

  move $a1, $a3
  li $a2, TEXT_CAP
  jal read_text_file
  bltz $v0, load_fail

parse_loop: # one parse_double per element, ntimes
  beqz $s1, load_ok
  move $a0, $s2
  jal parse_double
  bnez $v1, load_fail
  s.d $f0, 0($s0)
  move $s2, $v0
  addiu $s0, $s0, 8
  addiu $s1, $s1, -1
  j parse_loop

load_ok:
  move $v0, $zero
  j load_cleanup
load_fail:
  li $v0, -1

load_cleanup:
  lw $ra, 12($sp)
  lw $s0, 8($sp)
  lw $s1, 4($sp)
  lw $s2, 0($sp)
  addiu $sp, $sp, 16
  jr $ra

# $a0 a, $a1 b, $a2 c, $a3 n
add_matrices:                  # C[k] = A[k] + B[k]
  blez $a3, add_done
  l.d $f0, 0($a0)
  l.d $f2, 0($a1)
  add.d $f4, $f0, $f2
  s.d $f4, 0($a2)
  addiu $a0, $a0, 8
  addiu $a1, $a1, 8
  addiu $a2, $a2, 8
  addiu $a3, $a3, -1
  j add_matrices
add_done:
  jr $ra

# $a0 fd, $a1 buffer, $a2 length
# ec: 0 / -1
# $t0 fd, $t1 ptr, $t2 bytes lef
write_all:
  move $t0, $a0
  move $t1, $a1
  move $t2, $a2


write_loop: # loops and if nothign read 0
  blez $t2, write_ok
  move $a0, $t0
  move $a1, $t1
  move $a2, $t2
  li $v0, 15
  syscall
  blez $v0, write_fail
  addu $t1, $t1, $v0
  subu $t2, $t2, $v0
  j write_loop
write_ok:
  move $v0, $zero
  jr $ra
write_fail:
  li $v0, -1
  jr $ra

#$a0 filename, $a1 C base, $a2 rows, $a3 cols
# open file and write
# $s0 fd, $s1 element ptr, $s2 rows left, $s3 cols, $s4 col idx
write_matrix:
  addiu $sp, $sp, -24
  sw $ra, 20($sp)
  sw $s0, 16($sp)
  sw $s1, 12($sp)
  sw $s2, 8($sp)
  sw $s3, 4($sp)
  sw $s4, 0($sp)
  move $s1, $a1
  move $s2, $a2
  move $s3, $a3

  li $a1, 1
  li $v0, 13
  syscall
  bltz $v0, matrix_open_fail
  move $s0, $v0

# one row per pass
row_loop:
  beqz $s2, matrix_ok
  move $s4, $zero

# number + space, newline after last col
col_loop:
  l.d $f12, 0($s1)
  la $a0, number_buffer
  jal format_double6
  move $a2, $v0
  move $a0, $s0
  la $a1, number_buffer
  jal write_all
  bnez $v0, matrix_fail

  addiu $s1, $s1, 8
  addiu $s4, $s4, 1
  la $a1, space_char
  bne $s4, $s3, put_sep
  la $a1, newline_char
put_sep:
  move $a0, $s0
  li $a2, 1
  jal write_all
  bnez $v0, matrix_fail
  bne $s4, $s3, col_loop

  addiu $s2, $s2, -1
  j row_loop

matrix_ok:
  close_fd($s0)
  move $v0, $zero
  j matrix_cleanup

matrix_fail:
  close_fd($s0)
  li $v0, -1
  j matrix_cleanup

matrix_open_fail:
  li $v0, -1

matrix_cleanup:
  lw $ra, 20($sp)
  lw $s0, 16($sp)
  lw $s1, 12($sp)
  lw $s2, 8($sp)
  lw $s3, 4($sp)
  lw $s4, 0($sp)
  addiu $sp, $sp, 24
  jr $ra

.include "numeric_text.asm"
