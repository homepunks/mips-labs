# Every procedure preserves $s0-$s7, $sp and $f20-$f31.
.data
.align 3
num_ten:     .double 10.0
num_zero:    .double 0.0
num_million: .double 1000000.0

.text
.globl parse_uint
.globl parse_double
.globl format_double6

# parse_uint($a0 = cursor in NUL-terminated text)
# Success: $v0 = nonnegative signed-32-bit integer,
#          $v1 = address immediately after the token (before whitespace).
# Failure: $v1 = 0. Accepts digits only; skips leading whitespace.
parse_uint:
    move  $t0 $a0
pu_skip:
    lbu   $t1 0($t0)
    beq   $t1 32 pu_skip_one
    beq   $t1 9 pu_skip_one
    beq   $t1 10 pu_skip_one
    beq   $t1 13 pu_skip_one
    j     pu_start
pu_skip_one:
    addiu $t0 $t0 1
    j     pu_skip
pu_start:
    move  $t2 $zero
    move  $t3 $zero
pu_digits:
    lbu   $t1 0($t0)
    bltu  $t1 48 pu_end
    bgtu  $t1 57 pu_end
    addiu $t1 $t1 -48
    li    $t4 214748364
    bgtu  $t2 $t4 pu_error
    bne   $t2 $t4 pu_accumulate
    bgtu  $t1 7 pu_error
pu_accumulate:
    mul   $t2 $t2 10
    addu  $t2 $t2 $t1
    addiu $t0 $t0 1
    addiu $t3 $t3 1
    j     pu_digits
pu_end:
    beqz  $t3 pu_error
    beqz  $t1 pu_success
    beq   $t1 32 pu_success
    beq   $t1 9 pu_success
    beq   $t1 10 pu_success
    beq   $t1 13 pu_success
pu_error:
    move  $v0 $zero
    move  $v1 $zero
    jr    $ra
pu_success:
    move  $v0 $t2
    move  $v1 $t0
    jr    $ra

# parse_double($a0 = cursor in NUL-terminated text)
# Success: $f0/$f1 = binary64 number, $v0 = first unread address, $v1 = 0.
# No token after whitespace: $v1 = 1. Malformed token: $v1 = -1.
# Grammar: [+-]?[0-9]+(\.[0-9]{1,6})?
# Designed for the lab's bounded magnitudes; not a complete strtod().
parse_double:
    move  $t0 $a0
pd_skip:
    lbu   $t1 0($t0)
    beq   $t1 32 pd_skip_one
    beq   $t1 9 pd_skip_one
    beq   $t1 10 pd_skip_one
    beq   $t1 13 pd_skip_one
    beqz  $t1 pd_eof
    j     pd_start
pd_skip_one:
    addiu $t0 $t0 1
    j     pd_skip
pd_start:
    move  $t3 $zero
    beq   $t1 45 pd_minus
    bne   $t1 43 pd_number
    addiu $t0 $t0 1
    j     pd_number
pd_minus:
    li    $t3 1
    addiu $t0 $t0 1
pd_number:
    l.d   $f2 num_ten
    l.d   $f4 num_zero
    move  $t2 $zero
pd_integer:
    lbu   $t1 0($t0)
    bltu  $t1 48 pd_integer_end
    bgtu  $t1 57 pd_integer_end
    addiu $t5 $t1 -48
    mtc1  $t5 $f6
    cvt.d.w $f6 $f6
    mul.d $f4 $f4 $f2
    add.d $f4 $f4 $f6
    addiu $t0 $t0 1
    addiu $t2 $t2 1
    j     pd_integer
pd_integer_end:
    beqz  $t2 pd_error
    bne   $t1 46 pd_end
    addiu $t0 $t0 1
    move  $t4 $zero
    li    $t5 1
    mtc1  $t5 $f8
    cvt.d.w $f8 $f8
pd_fraction:
    lbu   $t1 0($t0)
    bltu  $t1 48 pd_fraction_end
    bgtu  $t1 57 pd_fraction_end
    addiu $t5 $t1 -48
    mtc1  $t5 $f6
    cvt.d.w $f6 $f6
    div.d $f8 $f8 $f2
    mul.d $f10 $f6 $f8
    add.d $f4 $f4 $f10
    addiu $t0 $t0 1
    addiu $t4 $t4 1
    bgtu  $t4 6 pd_error
    j     pd_fraction
pd_fraction_end:
    beqz  $t4 pd_error
pd_end:
    beqz  $t1 pd_success
    beq   $t1 32 pd_success
    beq   $t1 9 pd_success
    beq   $t1 10 pd_success
    beq   $t1 13 pd_success
pd_error:
    move  $v0 $t0
    li    $v1 -1
    jr    $ra
pd_eof:
    move  $v0 $t0
    li    $v1 1
    jr    $ra
pd_success:
    mov.d $f0 $f4
    beqz  $t3 pd_positive
    neg.d $f0 $f0
pd_positive:
    move  $v0 $t0
    move  $v1 $zero
    jr    $ra

# format_double6($f12/$f13 = finite value, $a0 = output buffer >= 32 bytes)
# Precondition: absolute value <= 20000.0 (covers all lab sums).
# Writes fixed-point ASCII with exactly six fractional digits plus NUL.
# Returns $v0 = byte count EXCLUDING NUL. Rounds for display only.
# A value that rounds to zero is written as 0.000000 (no negative zero).
format_double6:
    move  $t0 $a0
    move  $t1 $a0
    abs.d $f0 $f12
    trunc.w.d $f2 $f0
    mfc1  $t2 $f2
    cvt.d.w $f4 $f2
    sub.d $f6 $f0 $f4
    l.d   $f8 num_million
    mul.d $f6 $f6 $f8
    round.w.d $f10 $f6
    mfc1  $t3 $f10
    li    $t4 1000000
    bne   $t3 $t4 fd_sign
    addiu $t2 $t2 1
    move  $t3 $zero
fd_sign:
    or    $t4 $t2 $t3
    beqz  $t4 fd_int_start
    l.d   $f14 num_zero
    c.lt.d $f12 $f14
    bc1f  fd_int_start
    li    $t4 45
    sb    $t4 0($t1)
    addiu $t1 $t1 1
fd_int_start:
    li    $t5 10000
    li    $t7 10
fd_divisor:
    bgeu  $t2 $t5 fd_int_digit
    beq   $t5 1 fd_int_digit
    divu  $t5 $t7
    mflo  $t5
    j     fd_divisor
fd_int_digit:
    divu  $t2 $t5
    mflo  $t6
    mfhi  $t2
    addiu $t6 $t6 48
    sb    $t6 0($t1)
    addiu $t1 $t1 1
    divu  $t5 $t7
    mflo  $t5
    bnez  $t5 fd_int_digit
    li    $t6 46
    sb    $t6 0($t1)
    addiu $t1 $t1 1
    li    $t5 100000
fd_frac_digit:
    divu  $t3 $t5
    mflo  $t6
    mfhi  $t3
    addiu $t6 $t6 48
    sb    $t6 0($t1)
    addiu $t1 $t1 1
    divu  $t5 $t7
    mflo  $t5
    bnez  $t5 fd_frac_digit
    sb    $zero 0($t1)
    subu  $v0 $t1 $t0
    jr    $ra