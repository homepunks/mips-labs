.data
txt: .asciiz "no, just no."

.text
    li $v0, 4
    la $a0, txt
    syscall

    li $v0, 10
    syscall
