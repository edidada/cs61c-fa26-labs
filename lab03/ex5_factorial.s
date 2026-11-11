.globl factorial

.data
n: .word 8

.text
# Don't worry about understanding the code in main
# You'll learn more about function calls in lecture soon
main:
    la t0, n
    lw a0, 0(t0)
    jal ra, factorial

    addi a1, a0, 0
    addi a0, x0, 1
    ecall # Print Result

    addi a1, x0, '\n'
    addi a0, x0, 11
    ecall # Print newline

    addi a0, x0, 10
    ecall # Exit

# factorial takes one argument:
# a0 contains the number which we want to compute the factorial of
# The return value should be stored in a0
factorial:
    mv t0, a0
    li a0, 1
factorial_loop:
    beq t0, zero, factorial_done
    mul a0, a0, t0
    addi t0, t0, -1
    j factorial_loop
factorial_done:

    # This is how you return from a function. You'll learn more about this later.
    # This should be the last line in your program.
    jr ra
