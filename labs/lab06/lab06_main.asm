.macro p_string(%label)
    li  $v0, 4
    la  $a0, %label
    syscall
.end_macro

.macro p_char(%c)
    li  $v0, 11
    li  $a0, %c
    syscall
.end_macro

.macro p_int(%reg)
    li  $v0, 1
    move $a0, %reg
    syscall
.end_macro

.data
array_open:  .asciiz "Array["
array_close: .asciiz "]"
empty_txt:   .asciiz "Empty"
max_label:   .asciiz "Max:"
min_label:   .asciiz "Min:"

.text
    move  $s0, $a0
    move  $s1, $a1

    p_string(array_open)
    beqz  $s0, show_empty
    li    $s2, 0                
print_loop:
    bge   $s2, $s0, print_done
    beqz  $s2, no_comma
    p_char(44)             
no_comma:
    sll   $t0, $s2, 2
    addu  $t0, $s1, $t0
    lw    $a0, 0($t0)  
    li    $v0, 4
    syscall
    addiu $s2, $s2, 1
    j     print_loop
show_empty:
    p_string(empty_txt)
print_done:
    p_string(array_close)
    p_char(10)

    li    $s3, 0        
    li    $s4, 0        
    beqz  $s0, results  
    sll   $a0, $s0, 2   
    li    $v0, 9
    syscall
    move  $s3, $v0
    li    $s2, 0
arg_loop:
    bge   $s2, $s0, results
    sll   $t0, $s2, 2
    addu  $t0, $s1, $t0
    lw    $t1, 0($t0)  
    li    $t2, 0       
    li    $t5, 10
    lbu   $t3, 0($t1)
    beqz  $t3, skip_arg        
digit_loop:
    lbu   $t3, 0($t1)
    beqz  $t3, valid            
    blt   $t3, 48, skip_arg
    bgt   $t3, 57, skip_arg
    addiu $t3, $t3, -48         
    mul   $t2, $t2, $t5         
    addu  $t2, $t2, $t3
    addiu $t1, $t1, 1
    j     digit_loop
valid:
    sll   $t4, $s4, 2
    addu  $t4, $s3, $t4
    sw    $t2, 0($t4)           
    addiu $s4, $s4, 1
skip_arg:
    addiu $s2, $s2, 1
    j     arg_loop

results:
    beqz  $s4, no_numbers       
    move  $a0, $s3
    move  $a1, $s4
    jal   recursive_max
    move  $s5, $v0              
    move  $a0, $s3
    move  $a1, $s4
    jal   recursive_min
    move  $s6, $v0
    p_string(max_label)
    p_int($s5)
    p_char(10)
    p_string(min_label)
    p_int($s6)
    j     finish
no_numbers:
    p_string(max_label)
    p_string(empty_txt)
    p_char(10)
    p_string(min_label)
    p_string(empty_txt)
finish:
    li    $v0, 10
    syscall
