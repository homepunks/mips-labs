.eqv MAX_TERMS 20
.eqv SEQ_BYTES 80  #  to be kept in sync with MAX_TERMS * sizeof(word)

.data
.align 2
sequence: .space SEQ_BYTES
prompt_first: .asciiz "Enter first term: "
prompt_diff:  .asciiz "Enter common difference: "
prompt_num:   .asciiz "Enter number of terms (1-20): "
prompt_excl:  .asciiz "Enter excluded value: "

out_seq:  .asciiz "Stored sequence: "
out_skip: .asciiz "Skipped terms: "
out_seq_none: .asciiz "Stored sequence: none\n"

.text
    li $v0, 4
    la $a0, prompt_first
    syscall

    li $v0, 5
    syscall
    move $s0, $v0

    li $v0, 4
    la $a0, prompt_diff
    syscall

    li $v0, 5
    syscall
    move $s1, $v0

    li $v0, 4
    la $a0, prompt_num
    syscall

    li $v0, 5
    syscall
    move $s2, $v0

    li $v0, 4
    la $a0, prompt_excl
    syscall

    li $v0, 5
    syscall
    move $s3, $v0

    # iter variables
    li $t0, 0  
    li $t1, 0
    move $t2, $s0 # current
    li $t3, 0   # stored
    li $t4, 0   # skipped
    la $s4, sequence

    fill_loop:
        bge $t0, $s2, fill_done
        bne $t2, $s3, else_1
        addi $t4, $t4, 1 
        j else_1_done
        else_1:
            sll $t5, $t3, 2
            add $t6, $s4, $t5
            sw $t2, 0($t6)
            addi $t3, $t3, 1
        else_1_done:
            add $t2, $t2, $s1
            addi $t0, $t0, 1
            j fill_loop
          
    fill_done:
        bne $t3, $zero, else_2
        li $v0, 4
        la $a0, out_seq_none
        syscall 
        j else_2_done
        else_2:
            li $v0, 4
            la $a0, out_seq
            syscall
            li $t1, 0

            while_1:
                bge $t1, $t3, while_1_done
                beq $t1, $zero, if69
                li $v0, 11
                li $a0, 32
                syscall
                if69:
                    sll $t5, $t1, 2
                    add $t6, $s4, $t5
                    lw $t7, 0($t6)

                    li $v0, 1
                    move $a0, $t7
                    syscall
                   
                    addi $t1, $t1, 1
                    j while_1

            while_1_done:
                li $v0, 11
                li $a0, 10
                syscall
        else_2_done:
            li $v0, 4
            la $a0, out_skip
            syscall
            li $v0, 1
            move $a0, $t4
            syscall

            li $v0, 11
            li $a0, 10
            syscall


    li $v0, 10
    syscall

