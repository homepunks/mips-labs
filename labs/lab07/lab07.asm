.eqv FRAME_BYTES 262144
.eqv CENTER 128

.data
  .align 2
DISPLAY: .space FRAME_BYTES
fzero:   .float 0.0
fone:    .float 1.0
fstep:   .float 0.1

.text
master:
  la $s7, DISPLAY
  jal clear_FFFFFFF
  li $s0, 63

fillscreen:
  move $a0, $s0
  li $a1, 0x00FF0000
  jal draw_circle
  addiu $s0, $s0, -1
  bgez $s0, fillscreen

  li $s0, 64

borderline:
  move $a0, $s0
  li $a1, 0x00000000
  jal draw_circle
  addiu $s0, $s0, 1
  ble $s0, 68, borderline
  li $a0, 64
  li $a1, 16
  li $a2, 0x00000000
  jal draw_ellipse
  li $a0, 16
  li $a1, 64
  li $a2, 0x00000000
  jal draw_ellipse

  li $v0, 10
  syscall

clear_FFFFFFF:
  li $t0, 0x00FFFFFF
  move $t1, $s7
  li $t2, 65536

whiten:
  sw $t0, 0($t1)
  addiu $t1, $t1, 4
  addiu $t2, $t2, -1
  bgtz $t2, whiten
  jr $ra

set_pixel_color:
  sll $t0, $a1, 8
  addu $t0, $t0, $a0
  sll $t0, $t0, 2
  addu $t1, $s7, $t0
  sw $a2, 0($t1)
  jr $ra

draw_circle:
  addiu $sp, $sp, -40
  s.s $f20, 0($sp)
  s.s $f21, 4($sp)
  s.s $f22, 8($sp)
  s.s $f23, 12($sp)
  s.s $f24, 16($sp)
  s.s $f25, 20($sp)
  s.s $f26, 24($sp)
  s.s $f27, 28($sp)
  sw $s0, 32($sp)
  sw $ra, 36($sp)
  move $s0, $a1
  mtc1 $a0, $f4
  cvt.s.w $f4, $f4
  mul.s $f21, $f4, $f4
  li $t0, CENTER
  mtc1 $t0, $f20
  cvt.s.w $f20, $f20
  sub.s $f22, $f20, $f4
  add.s $f23, $f20, $f4
  l.s $f24, fstep
  l.s $f25, fzero

sweep:
  c.le.s $f22, $f23
  bc1f restore_sweep
  sub.s $f27, $f22, $f20
  mul.s $f4, $f27, $f27
  sub.s $f4, $f21, $f4
  c.lt.s $f4, $f25
  bc1f circlesqrt
  mov.s $f4, $f25

circlesqrt:
  sqrt.s $f26, $f4

  cvt.w.s $f4, $f22
  mfc1 $a0, $f4
  add.s $f4, $f20, $f26
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color

  cvt.w.s $f4, $f22
  mfc1 $a0, $f4
  sub.s $f4, $f20, $f26
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color

  add.s $f4, $f20, $f26
  cvt.w.s $f4, $f4
  mfc1 $a0, $f4
  add.s $f4, $f20, $f27
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color
  sub.s $f4, $f20, $f26
  cvt.w.s $f4, $f4
  mfc1 $a0, $f4
  add.s $f4, $f20, $f27
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color

  add.s $f22, $f22, $f24
  j sweep

restore_sweep:
  l.s $f20, 0($sp)
  l.s $f21, 4($sp)
  l.s $f22, 8($sp)
  l.s $f23, 12($sp)
  l.s $f24, 16($sp)
  l.s $f25, 20($sp)
  l.s $f26, 24($sp)
  l.s $f27, 28($sp)
  lw $s0, 32($sp)
  lw $ra, 36($sp)
  addiu $sp, $sp, 40
  jr $ra

draw_ellipse:
  addiu $sp, $sp, -56
  s.s $f20, 0($sp)
  s.s $f21, 4($sp)
  s.s $f22, 8($sp)
  s.s $f23, 12($sp)
  s.s $f24, 16($sp)
  s.s $f25, 20($sp)
  s.s $f26, 24($sp)
  s.s $f27, 28($sp)
  s.s $f28, 32($sp)
  s.s $f29, 36($sp)
  s.s $f30, 40($sp)
  sw $s0, 44($sp)
  sw $ra, 48($sp)
  move $s0, $a2
  mtc1 $a0, $f21
  cvt.s.w $f21, $f21
  mtc1 $a1, $f22
  cvt.s.w $f22, $f22
  mul.s $f23, $f21, $f21
  mul.s $f24, $f22, $f22
  li $t0, CENTER
  mtc1 $t0, $f20
  cvt.s.w $f20, $f20
  l.s $f27, fstep
  l.s $f28, fzero
  l.s $f29, fone
  sub.s $f25, $f20, $f21
  add.s $f26, $f20, $f21

ellipsex:
  c.le.s $f25, $f26
  bc1f ellipsex_done

  sub.s $f4, $f25, $f20
  mul.s $f4, $f4, $f4
  div.s $f4, $f4, $f23
  sub.s $f4, $f29, $f4
  c.lt.s $f4, $f28
  bc1f ellipsex_sqrt
  mov.s $f4, $f28

ellipsex_sqrt:
  sqrt.s $f4, $f4
  mul.s $f30, $f4, $f22
  cvt.w.s $f4, $f25
  mfc1 $a0, $f4
  add.s $f4, $f20, $f30
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color
  cvt.w.s $f4, $f25
  mfc1 $a0, $f4
  sub.s $f4, $f20, $f30
  cvt.w.s $f4, $f4
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color
  add.s $f25, $f25, $f27
  j ellipsex
ellipsex_done:
  sub.s $f25, $f20, $f22
  add.s $f26, $f20, $f22

ellipsey:
  c.le.s $f25, $f26
  bc1f ellipsey_done
  sub.s $f4, $f25, $f20
  mul.s $f4, $f4, $f4
  div.s $f4, $f4, $f24
  sub.s $f4, $f29, $f4
  c.lt.s $f4, $f28
  bc1f ellipsey_sqrt
  mov.s $f4, $f28

ellipsey_sqrt:
  sqrt.s $f4, $f4
  mul.s $f30, $f4, $f21
  add.s $f4, $f20, $f30
  cvt.w.s $f4, $f4
  mfc1 $a0, $f4
  cvt.w.s $f4, $f25
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color
  sub.s $f4, $f20, $f30
  cvt.w.s $f4, $f4
  mfc1  $a0, $f4
  cvt.w.s $f4, $f25
  mfc1 $a1, $f4
  move $a2, $s0
  jal set_pixel_color

  add.s $f25, $f25, $f27
  j ellipsey

ellipsey_done:
  l.s $f20, 0($sp)
  l.s $f21, 4($sp)
  l.s $f22, 8($sp)
  l.s $f23, 12($sp)
  l.s $f24, 16($sp)
  l.s $f25, 20($sp)
  l.s $f26, 24($sp)
  l.s $f27, 28($sp)
  l.s $f28, 32($sp)
  l.s $f29, 36($sp)
  l.s $f30, 40($sp)
  lw $s0, 44($sp)
  lw $ra, 48($sp)
  addiu $sp, $sp, 56
  jr $ra
