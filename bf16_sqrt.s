    .equ BF16_SIGN_MASK, 0x8000  
    .equ BF16_EXP_MASK,  0x7F80
    .equ BF16_MANT_MASK, 0x007F
    .equ BF16_EXP_BIAS,  127

.data
    msg_pass:   .asciz "All tests passed\n"
    msg_fail:   .asciz "Tests failed\n"

.text
.globl main

main:
    # --------------------
    # bf16_sqrt(a0) -> a0
    # --------------------

    li      a0, 0x7FA5
    jal     ra, bf16_sqrt
    li      t6, 0x7FA5
    bne     a0, t6, fail

    # +Inf
    li      a0, 0x7F80
    jal     ra, bf16_sqrt
    li      t6, 0x7F80
    bne     a0, t6, fail

    # -Inf -> NaN
    li      a0, 0xFF80
    jal     ra, bf16_sqrt
    li      t6, 0x7FC0
    bne     a0, t6, fail

    # +0
    li      a0, 0x0000
    jal     ra, bf16_sqrt
    li      t6, 0x0000
    bne     a0, t6, fail

    # -0 treated as +0
    li      a0, 0x8000
    jal     ra, bf16_sqrt
    li      t6, 0x0000
    bne     a0, t6, fail

    # Negative finite number -> NaN
    li      a0, 0xC000          # -2.0
    jal     ra, bf16_sqrt
    li      t6, 0x7FC0
    bne     a0, t6, fail

    # Subnormal input (flush to zero)
    li      a0, 0x0001          # smallest subnormal
    jal     ra, bf16_sqrt
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x007F          # largest subnormal
    jal     ra, bf16_sqrt
    li      t6, 0x0000
    bne     a0, t6, fail

    # Even exponent: do not double mantissa
    li      a0, 0x4080          # 4.0
    jal     ra, bf16_sqrt
    li      t6, 0x4000          # 2.0
    bne     a0, t6, fail

    li      a0, 0x4180          # 16.0
    jal     ra, bf16_sqrt
    li      t6, 0x4080          # 4.0
    bne     a0, t6, fail

    li      a0, 0x4110          # 9.0
    jal     ra, bf16_sqrt
    li      t6, 0x4040          # 3.0
    bne     a0, t6, fail

    # Odd exponent: shift mantissa left before halving
    li      a0, 0x4000          # 2.0
    jal     ra, bf16_sqrt
    li      t6, 0x3FB5          # ¡Ö1.4142 (truncated)
    bne     a0, t6, fail

    li      a0, 0x4040          # 3.0
    jal     ra, bf16_sqrt
    li      t6, 0x3FDD          # ¡Ö1.732 (truncated)
    bne     a0, t6, fail

    # Need left normalization (result < 128)
    li      a0, 0x3F00          # 0.5
    jal     ra, bf16_sqrt
    li      t6, 0x3F35          # ¡Ö0.7071 (truncated)
    bne     a0, t6, fail


# --------------------
# All tests passed
# --------------------
all_pass:
    la      a0, msg_pass
    li      a7, 4
    ecall
    li      a0, 0
    li      a7, 10
    ecall

# --------------------
# Any test failed
# --------------------
fail:
    la      a0, msg_fail
    li      a7, 4
    ecall
    li      a0, 1
    li      a7, 10
    ecall


bf16_sqrt:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a0, 7
    andi    t1, t1, 0xFF
    andi    t2, a0, 0x7F
    li      t6, 0xFF
    bne     t1, t6, chk_zero
    bnez    t2, ret_a
    bnez    t0, ret_nan
    j       ret_a

chk_zero:
    or      t6, t1, t2
    beqz    t6, ret_zero
    bnez    t0, ret_nan
    beqz    t1, ret_zero
    li      t6, 127
    sub     a2, t1, t6
    li      a3, 0x80
    or      a3, a3, t2
    andi    t6, a2, 1
    beqz    t6, get_new_exp
odd_exp:
    slli    a3, a3, 1
    addi    a2, a2, -1
get_new_exp:
    srai    a2, a2, 1
    li      t6, 127
    add     t3, a2, t6
bin_search:
    li      a4, 90
    li      a5, 256
    li      t4, 128
search_for:
    bgtu    a4, a5, norm_result
    add     a6, a4, a5
    srli    a6, a6, 1
    mv      a0, a6
    mv      a1, a6
    jal     ra, mul_aux
    srli    t6, a0, 7
    bgeu    a3, t6, le_ok
    addi    a5, a6, -1
    j       search_for
le_ok:
    mv      t4, a6
    addi    a4, a6, 1
    j       search_for
norm_result:
    li      t6, 256
    blt     t4, t6, chk_if_norm_up
    srli    t4, t4, 1
    addi    t3, t3, 1
chk_if_norm_up:
    li      t6, 128
    bge     t4, t6, mant_ok
norm_up:
    li      t6, 128
    bge     t4, t6, mant_ok
    li      t6, 1
    ble     t3, t6, mant_ok
    slli    t4, t4, 1
    addi    t3, t3, -1
    j       norm_up
mant_ok:
    andi    t4, t4, 0x7F
    li      t6, 0xFF
    bgeu    t3, t6, ret_inf
    blez    t3, ret_zero
sqrt_result:
    andi    t3, t3, 0xFF
    slli    t3, t3, 7
    or      a0, t3, t4
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra

ret_a:
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra
ret_zero:
    li      a0, 0x0000
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra
ret_inf:
    li      a0, 0x7F80
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra
ret_nan:
    li      a0, 0x7FC0
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra

mul_aux:
    li      t6, 0
mul_for:
    beqz    a1, mul_done
    andi    t2, a1, 1
    beqz    t2, skip_add
    add     t6, t6, a0
skip_add:
    srli    a1, a1, 1
    slli    a0, a0, 1
    j       mul_for
mul_done:
    mv      a0, t6
    jr      ra
