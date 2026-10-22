.macro open_frame
  addiu $sp, $sp, -16
  sw $ra, 12($sp)
  sw $s0, 8($sp)
  sw $s1, 4($sp)
  sw $s2, 0($sp)
.end_macro

.macro close_frame
  lw $ra, 12($sp)
  lw $s0, 8($sp)
  lw $s1, 4($sp)
  lw $s2, 0($sp)
  addiu $sp, $sp, 16
.end_macro

.text
.globl recursive_max
.globl recursive_min

recursive_max:
  open_frame
  lw $s0, 0($a0)
  li $t0, 1
  beq   $a1, $t0, basecasemax
  addiu $a0, $a0, 4
  addiu $a1, $a1, -1
  jal recursive_max
  ble $s0, $v0, pass_back_max
  move $v0, $s0
  j pass_back_max

  basecasemax:
    move $v0, $s0
  
  pass_back_max:
    close_frame
    jr $ra

recursive_min:
    open_frame
    lw    $s0, 0($a0)
    li    $t0, 1
    beq   $a1, $t0, basecasemin
    addiu $a0, $a0, 4
    addiu $a1, $a1, -1
    jal   recursive_min
    bge   $s0, $v0, pass_back_min
    move  $v0, $s0
    j     pass_back_min

  basecasemin:
      move  $v0, $s0

  pass_back_min:
      close_frame
      jr    $ra
