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
    # ... run tests ...

# --------------------
# bf16_isnan(a0)
# --------------------
    li      a0, 0x7FC1                 # NaN
    jal     ra, bf16_isnan
    li      t6, 1
    bne     a0, t6, fail

    li      a0, 0x7F80                 # +Inf
    jal     ra, bf16_isnan
    li      t6, 0
    bne     a0, t6, fail

    li      a0, 0x4000                 # +2.0
    jal     ra, bf16_isnan
    li      t6, 0
    bne     a0, t6, fail

# --------------------
# bf16_isinf(a0)
# --------------------
    li      a0, 0x7F80                 # +Inf
    jal     ra, bf16_isinf
    li      t6, 1
    bne     a0, t6, fail

    li      a0, 0xFF80                 # -Inf
    jal     ra, bf16_isinf
    li      t6, 1
    bne     a0, t6, fail

    li      a0, 0x7FC1                 # NaN
    jal     ra, bf16_isinf
    li      t6, 0
    bne     a0, t6, fail

# --------------------
# bf16_iszero(a0)
# --------------------
    li      a0, 0x0000                 # +0
    jal     ra, bf16_iszero
    li      t6, 1
    bne     a0, t6, fail

    li      a0, 0x8000                 # -0
    jal     ra, bf16_iszero
    li      t6, 1
    bne     a0, t6, fail

    li      a0, 0x4000                 # 2.0
    jal     ra, bf16_iszero
    li      t6, 0
    bne     a0, t6, fail

# --------------------
# f32_to_bf16(a0: f32 bits) -> a0: bf16 bits
# --------------------
    li      a0, 0x3F800000             # 1.0f
    jal     ra, f32_to_bf16
    li      t6, 0x3F80                  # 1.0 (bf16)
    bne     a0, t6, fail

    li      a0, 0x40400000             # 3.0f
    jal     ra, f32_to_bf16
    li      t6, 0x4040                  # 3.0 (bf16)
    bne     a0, t6, fail

    li      a0, 0x7FC00000             # quiet NaN
    jal     ra, f32_to_bf16
    li      t6, 0x7FC0
    bne     a0, t6, fail

# --------------------
# bf16_to_f32(a0: bf16 bits) -> a0: f32 bits
# --------------------
    li      a0, 0x3F80                 # 1.0 (bf16)
    jal     ra, bf16_to_f32
    li      t6, 0x3F800000
    bne     a0, t6, fail

    li      a0, 0x4040                 # 3.0 (bf16)
    jal     ra, bf16_to_f32
    li      t6, 0x40400000
    bne     a0, t6, fail

    li      a0, 0x7FC1                 # NaN with payload -> preserved in upper 16 bits
    jal     ra, bf16_to_f32
    li      t6, 0x7FC10000
    bne     a0, t6, fail

# --------------------
# bf16_add(a0, a1) -> a0
# --------------------
    li      a0, 0x3F80                 # 1.0 + 2.0 = 3.0
    li      a1, 0x4000
    jal     ra, bf16_add
    li      t6, 0x4040
    bne     a0, t6, fail

    li      a0, 0x4040                 # 3.0 + (-1.0) = 2.0
    li      a1, 0xBF80
    jal     ra, bf16_add
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0x0000                 # 0 + 1.0 = 1.0
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      t6, 0x3F80
    bne     a0, t6, fail

    li      a0, 0x7F80                 # +Inf + -Inf = NaN
    li      a1, 0xFF80
    jal     ra, bf16_add
    li      t6, 0x7FC0
    bne     a0, t6, fail

    li      a0, 0x7FC1                 # NaN + 1.0 = NaN (propagate payload)
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      t6, 0x7FC1
    bne     a0, t6, fail

    li      a0, 0x4000                 # 2.0 + tiny subnormal (>= 9 ulps apart) -> unchanged
    li      a1, 0x0001                 # smallest subnormal
    jal     ra, bf16_add
    li      t6, 0x4000
    bne     a0, t6, fail

# --------------------
# bf16_sub(a0, a1) -> a0
# --------------------
    li      a0, 0x4040                 # 3.0 - 1.0 = 2.0
    li      a1, 0x3F80
    jal     ra, bf16_sub
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0x3F80                 # 1.0 - 3.0 = -2.0
    li      a1, 0x4040
    jal     ra, bf16_sub
    li      t6, 0xC000
    bne     a0, t6, fail

    li      a0, 0x0000                 # 0 - 1.0 = -1.0
    li      a1, 0x3F80
    jal     ra, bf16_sub
    li      t6, 0xBF80
    bne     a0, t6, fail

    li      a0, 0x7F80                 # +Inf - +Inf = NaN
    li      a1, 0x7F80
    jal     ra, bf16_sub
    li      t6, 0x7FC0
    bne     a0, t6, fail

    li      a0, 0x7FC2                 # NaN - 1.0 = NaN (propagate payload)
    li      a1, 0x3F80
    jal     ra, bf16_sub
    li      t6, 0x7FC2
    bne     a0, t6, fail

    li      a0, 0x3F80                 # 1.0 - 0 = 1.0
    li      a1, 0x0000
    jal     ra, bf16_sub
    li      t6, 0x3F80
    bne     a0, t6, fail

# --------------------
# bf16_mul(a0, a1) -> a0
# --------------------
    li      a0, 0x4000                 # 2.0 * 3.0 = 6.0
    li      a1, 0x4040
    jal     ra, bf16_mul
    li      t6, 0x40C0                 # 6.0
    bne     a0, t6, fail

    li      a0, 0x3F80                 # 1.0 * -2.0 = -2.0
    li      a1, 0xC000
    jal     ra, bf16_mul
    li      t6, 0xC000
    bne     a0, t6, fail

    li      a0, 0x0000                 # 0 * 3.0 = 0
    li      a1, 0x4040
    jal     ra, bf16_mul
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x7F80                 # Inf * 0 = NaN
    li      a1, 0x0000
    jal     ra, bf16_mul
    li      t6, 0x7FC0
    bne     a0, t6, fail

    li      a0, 0x7FC1                 # NaN * 1.0 = NaN (propagate payload)
    li      a1, 0x3F80
    jal     ra, bf16_mul
    li      t6, 0x7FC1
    bne     a0, t6, fail

    li      a0, 0x0002                 # subnormal * 1.0 -> 0 (mul flush behavior here)
    li      a1, 0x3F80
    jal     ra, bf16_mul
    li      t6, 0x0000
    bne     a0, t6, fail

# --------------------
# bf16_div(a0, a1) -> a0
# --------------------
    li      a0, 0x4080                 # 4 / 2 = 2
    li      a1, 0x4000
    jal     ra, bf16_div
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0x4000                 # 2 / 4 = 0.5
    li      a1, 0x4080
    jal     ra, bf16_div
    li      t6, 0x3F00
    bne     a0, t6, fail

    li      a0, 0x4040                 # 3 / 3 = 1
    li      a1, 0x4040
    jal     ra, bf16_div
    li      t6, 0x3F80
    bne     a0, t6, fail

    li      a0, 0x3F80                 # x / 0 = +Inf (x > 0)
    li      a1, 0x0000
    jal     ra, bf16_div
    li      t6, 0x7F80
    bne     a0, t6, fail

    li      a0, 0x0000                 # 0 / x = 0
    li      a1, 0x3F80
    jal     ra, bf16_div
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x0001                 # subnormal / 1.0 = 0 (div flush-to-zero here)
    li      a1, 0x3F80
    jal     ra, bf16_div
    li      t6, 0x0000
    bne     a0, t6, fail

# --------------------
# All passed -> print and exit
# --------------------
all_pass:
    la      a0, msg_pass
    li      a7, 4
    ecall
    li      a0, 0                          # return code 0
    li      a7, 10
    ecall

# Any failure -> print and exit with code=1
fail:
    la      a0, msg_fail
    li      a7, 4
    ecall
    li      a0, 1
    li      a7, 10
    ecall


bf16_div:
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t2, a0, 7
    andi    t2, t2, 0xFF
    srli    t3, a1, 7
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x7F
    andi    t5, a1, 0x7F
    xor     a2, t0, t1
    li      t6, 0xFF
    bne     t3, t6, chk_b_zero
    bnez    t5, ret_b
    bne     t2, t6, ret_sign_zero
    bnez    t4, ret_sign_zero
    j       ret_nan

chk_b_zero:
    or      t6, t3, t5
    bnez    t6, chk_a_inf
    or      t6, t2, t4
    beqz    t6, ret_nan
    j       ret_inf

chk_a_inf:
    li      t6, 0xFF
    bne     t2, t6, chk_a_zero
    bnez    t4, ret_a
    j       ret_inf

chk_a_zero:
    or      t6, t2, t4
    bnez    t6, prep_mant
    j       ret_sign_zero

prep_mant:
    beqz    t2, a_is_norm
    ori     t4, t4, 0x80
    
a_is_norm:
    beqz    t3, div_a_b
    ori     t5, t5, 0x80

div_a_b:
    mv      a3, t4
    li      a6, 0  
    bgeu    a3, t5, div_no_scale
    slli    a3, a3, 1        
    li      a6, 1   
             
div_no_scale:
    sub     a3, a3, t5
 
    li      a4, 0
    li      t6, 7     
          
div_frac_for:
    beqz    t6, div_frac_done
    slli    a3, a3, 1        
    bltu    a3, t5, div_bit0
    sub     a3, a3, t5         
    slli    a4, a4, 1
    ori     a4, a4, 1        
    addi    t6, t6, -1
    j       div_frac_for

div_bit0:
    slli    a4, a4, 1        
    addi    t6, t6, -1
    j       div_frac_for

div_frac_done:
    li      t6, BF16_EXP_BIAS
    sub     a5, t2, t3
    add     a5, a5, t6

    bnez    t2, chk_incr_exp
    addi    a5, a5, -1
chk_incr_exp:
    bnez    t3, div_result
    addi    a5, a5, 1
    beqz    a6, div_result
    addi    a5, a5, -1

div_result:
    li      t6, 0xFF
    bge     a5, t6, ret_inf
    blez    a5, ret_sign_zero

    slli    a2, a2, 15
    andi    a5, a5, 0xFF
    slli    a5, a5, 7
    andi    a4, a4, 0x7F
    or      a0, a2, a5
    or      a0, a0, a4
    jr      ra


bf16_mul:
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t2, a0, 7
    andi    t2, t2, 0xFF
    srli    t3, a1, 7
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x7F
    andi    t5, a1, 0x7F
    xor     a2, t0, t1
    li      t6, 0xFF
    bne     t2, t6, chk_exp_b_full
    bnez    t4, ret_a
    or      t6, t3, t5
    beqz    t6, ret_nan
    j       ret_inf

chk_exp_b_full:
    li      t6, 0xFF
    bne     t3, t6, chk_if_zero
    bnez    t5, ret_b
    or      t6, t2, t4
    beqz    t6, ret_nan
    j       ret_inf

chk_if_zero:
    or      t6, t2, t4
    beqz    t6, ret_sign_zero
    or      t6, t3, t5
    beqz    t6, ret_sign_zero

exp_adjust:
    li      a3, 0
    bnez    t2, skip_a_norm
norm_a_for:
    andi    t6, t4, 0x80
    bnez    t6, break_1
    slli    t4, t4, 1
    addi    a3, a3, -1
    j       norm_a_for
break_1:
    li      t2, 1
    j       chk_b_norm
skip_a_norm:
    ori     t4, t4, 0x80

chk_b_norm:
    bnez    t3, b_is_norm
norm_b_for:
    andi    t6, t5, 0x80
    bnez    t6, break_2
    slli    t5, t5, 1
    addi    a3, a3, -1
    j       norm_b_for
break_2:
    li      t3, 1
    j       mult_a_b
b_is_norm:
    ori     t5, t5, 0x80

mult_a_b:
    mv      t6, t4
    mv      a6, t5
    li      a4, 0
mult_for:
    beqz    a6, mult_done
    andi    a5, a6, 1
    beqz    a5, skip_add
    add     a4, a4, t6
skip_add:
    srli    a6, a6, 1
    slli    t6, t6, 1
    j       mult_for
mult_done:
    li      t6, BF16_EXP_BIAS
    add     a5, t2, t3
    sub     a5, a5, t6
    add     a5, a5, a3

norm_result_mant:
    li      t6, 0x8000
    li      a6, 7
    and     t6, a4, t6
    beqz    t6, skip_1
    addi    a6, a6, 1
    addi    a5, a5, 1
skip_1:
    srl     a4, a4, a6
    andi    a4, a4, 0x7F

    li      t6, 0xFF
    bge     a5, t6, ret_inf
    bgtz    a5, mult_result
    li      t6, -6
    blt     a5, t6, ret_sign_zero
    li      t6, 1
    sub     t6, t6, a5
    srl     a4, a4, t6
    li      a5, 0

mult_result:
    slli    a2, a2, 15
    andi    a5, a5, 0xFF
    slli    a5, a5, 7
    andi    a4, a4, 0x7F
    or      a0, a2, a5
    or      a0, a0, a4
    jr      ra


bf16_sub:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    li      t0, BF16_SIGN_MASK
    xor     a1, a1, t0
    jal     ra, bf16_add
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jr      ra


bf16_add:
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t2, a0, 7
    andi    t2, t2, 0xFF
    srli    t3, a1, 7
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x7F
    andi    t5, a1, 0x7F
    li      t6, 0xFF
    bne     t2, t6, chk_b_inf_or_nan
    bnez    t4, ret_a
    bne     t3, t6, ret_a
    bnez    t5, ret_b
    beq     t0, t1, ret_b
    j       ret_nan

chk_b_inf_or_nan:
    beq     t3, t6, ret_b

check_zero:
    or      t6, t2, t4
    beqz    t6, ret_b
    or      t6, t3, t5
    beqz    t6, ret_a

check_normal:
    beqz    t2, skip_a
    ori     t4, t4, 0x80
skip_a:
    beqz    t3, adjust_exp
    ori     t5, t5, 0x80

adjust_exp:
    sub     a2, t2, t3
    li      t6, 9
    blez    a2, not_greater
    mv      a3, t2
    blt     a2, t6, shift_b
    j       ret_a
shift_b:
    srl     t5, t5, a2
    j       aligned

not_greater:
    beqz    a2, equal_diff
    mv      a3, t3
    sub     a6, x0, a2
    blt     a6, t6, shift_a
    j       ret_b
shift_a:
    srl     t4, t4, a6
    j       aligned

equal_diff:
    mv      a3, t2

aligned:
    bne     t0, t1, diff_sign
    mv      a4, t0
    add     a5, t4, t5
    andi    t6, a5, 0x100
    beqz    t6, compose_result
    srli    a5, a5, 1
    addi    a3, a3, 1
    li      t6, 0xFF
    bge     a3, t6, add_ret_inf
    j       compose_result

diff_sign:
    blt     t4, t5, mant_a_small
    mv      a4, t0
    sub     a5, t4, t5
    j       check_mant_zero
mant_a_small:
    mv      a4, t1
    sub     a5, t5, t4
check_mant_zero:
    beqz    a5, ret_zero

norm_for:
    andi    t6, a5, 0x80
    bnez    t6, compose_result
    slli    a5, a5, 1
    addi    a3, a3, -1
    blez    a3, ret_zero
    j       norm_for

compose_result:
    slli    a4, a4, 15
    andi    t6, a3, 0xFF
    slli    t6, t6, 7
    andi    a5, a5, 0x7F
    or      a0, a4, t6
    or      a0, a0, a5
    jr      ra

ret_a:
    jr      ra
ret_b:
    mv      a0, a1
    jr      ra
ret_zero:
    li      a0, 0x0000
    jr      ra
ret_sign_zero:
    slli    a0, a2, 15
    jr      ra
ret_nan:
    li      a0, 0x7FC0
    jr      ra
ret_inf:
    slli    a0, a2, 15
    li      t6, 0x7F80
    or      a0, a0, t6
    jr      ra
add_ret_inf:
    slli    a0, a4, 15
    li      t6, 0x7F80
    or      a0, a0, t6
    jr      ra


bf16_to_f32:
    slli    a0, a0, 16
    jr      ra


f32_to_bf16:
    mv      t0, a0
    srli    t1, t0, 23
    li      t2, 0xFF
    and     t1, t1, t2
    beq     t1, t2, is_NaN_or_Inf
    srli    t1, t0, 16
    andi    t1, t1, 1
    li      t2, 0x7FFF
    add     t1, t1, t2
    add     t0, t0, t1
    srli    a0, t0, 16
    jr      ra

is_NaN_or_Inf:
    srli    a0, t0, 16
    jr      ra


bf16_isnan:
    li      t1, BF16_EXP_MASK
    and     t0, a0, t1
    xor     t0, t0, t1
    slti    t0, t0, 1
    li      t2, BF16_MANT_MASK
    and     t1, a0, t2
    snez    t1, t1
    and     a0, t0, t1
    jr      ra


bf16_isinf:
    li      t1, BF16_EXP_MASK
    and     t0, a0, t1
    xor     t0, t0, t1
    slti    t0, t0, 1
    li      t2, BF16_MANT_MASK
    and     t1, a0, t2
    slti    t1, t1, 1
    and     a0, t0, t1
    jr      ra


bf16_iszero:
    li      t0, 0x7FFF
    and     t0, a0, t0
    slti    a0, t0, 1
    jr      ra
