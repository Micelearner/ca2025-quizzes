.data
    msg_pass:   .asciz "All tests passed.\n"
    msg_err1:   .asciz ": produces value "
    msg_err2:   .asciz " but encodes back to "
    msg_err3:   .asciz ": value "
    msg_err4:   .asciz " <= previous_value "
    nextline:   .asciz "\n"

.text
.globl main

main:
    jal     ra, Test
    beqz    a0, Fail
    la      a0, msg_pass
    li      a7, 4
    ecall
    li      a0, 0
    li      a7, 10
    ecall

Fail:
    li      a0, 1
    li      a7, 10
    ecall


# ------------------------------------------------------------
# Test function
# ------------------------------------------------------------
Test:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    li      s1, -1
    li      s2, 1
    li      s3, 0
    li      s7, 256

round_Trip:
    beq     s3, s7, test_End
    mv      s4, s3
    mv      a0, s4
    jal     ra, UF8_decode
    mv      s5, a0
    jal     ra, UF8_encode
    mv      s6, a0

    beq     s4, s6, check_Inc
    mv      a0, s4
    li      a7, 34
    ecall
    la      a0, msg_err1
    li      a7, 4
    ecall
    mv      a0, s5
    li      a7, 1
    ecall
    la      a0, msg_err2
    li      a7, 4
    ecall
    mv      a0, s6
    li      a7, 34
    ecall
    la      a0, nextline
    li      a7, 4
    ecall
    li      s2, 0

check_Inc:
    bgt     s5, s1, check_End
    mv      a0, s4
    li      a7, 34
    ecall
    la      a0, msg_err3
    li      a7, 4
    ecall
    mv      a0, s5
    li      a7, 1
    ecall
    la      a0, msg_err4
    li      a7, 4
    ecall
    mv      a0, s1
    li      a7, 1
    ecall
    la      a0, nextline
    li      a7, 4
    ecall
    li      s2, 0

check_End:
    mv      s1, s5
    addi    s3, s3, 1
    j       round_Trip

test_End:
    mv      a0, s2
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra


UF8_encode:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    li      t0, 16
    blt     a0, t0, small_End
    mv      t5, a0
    jal     ra, CLZ
    li      t6, 31
    sub     t6, t6, a0
    li      t1, 0
    li      t2, 0
    li      t0, 5
    blt     t6, t0, find_Exact
    addi    t1, t6, -4
    li      t0, 15
    ble     t1, t0, caculate_Off
    li      t1, 15

caculate_Off:
    li      t2, 0
    li      t3, 0
off_For:
    beq     t3, t1, adjust_Down
    slli    t2, t2, 1
    addi    t2, t2, 16
    addi    t3, t3, 1
    j       off_For

adjust_Down:
    beqz    t1, find_Exact
    bge     t5, t2, find_Exact
    addi    t2, t2, -16
    srli    t2, t2, 1
    addi    t1, t1, -1
    j       adjust_Down

find_Exact:
    li      t0, 15
    bge     t1, t0, Mantissa
up_For:
    slli    t3, t2, 1
    addi    t3, t3, 16
    blt     t5, t3, Mantissa
    mv      t2, t3
    addi    t1, t1, 1
    blt     t1, t0, up_For

Mantissa:
    sub     t3, t5, t2
    srl     t3, t3, t1

encode_End:
    slli    t1, t1, 4
    andi    t3, t3, 0x0F
    or      a0, t1, t3
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra

small_End:
    andi    a0, a0, 0xFF
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra


UF8_decode:
    andi    t1, a0, 0x0F
    srli    t2, a0, 4
    li      t3, 1
    sll     t3, t3, t2
    addi    t3, t3, -1
    slli    t3, t3, 4
    sll     t1, t1, t2
    add     a0, t1, t3
    jr      ra


CLZ:
    li      t1, 32
clz_For1:
    srli    t2, a0, 16
    beqz    t2, clz_For2
    addi    t1, t1, -16
    mv      a0, t2
clz_For2:
    srli    t2, a0, 8
    beqz    t2, clz_For3
    addi    t1, t1, -8
    mv      a0, t2
clz_For3:
    srli    t2, a0, 4
    beqz    t2, clz_For4
    addi    t1, t1, -4
    mv      a0, t2
clz_For4:
    srli    t2, a0, 2
    beqz    t2, clz_For5
    addi    t1, t1, -2
    mv      a0, t2
clz_For5:
    srli    t2, a0, 1
    beqz    t2, clz_End
    addi    t1, t1, -1
    mv      a0, t2
clz_End:
    sub     a0, t1, a0
    jr      ra
