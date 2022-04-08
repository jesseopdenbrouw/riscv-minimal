
# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .global Universal_Handler
  .type   _start, @function
  .type   Universal_Hander, @function
_start:
  # Initialize global pointer
.option push
.option norelax

	# Load global pointer and stack pointer
	la gp, __global_pointer$
        la sp, __stack_pointer$ 

	# set mtvec
	la t0, Universal_Handler
	csrw mtvec,t0
	# Next, set vectored mode
	#csrsi mtvec, 1

	# Enable interrupts
	li t0, 0x8 | (0x3<<11)
	csrw mstatus,t0

	li	x5,0

1:
	addi	zero,zero,1
	addi	zero,zero,2
	addi	zero,zero,3
	addi	zero,zero,4
	addi	zero,zero,5
	addi	zero,zero,6
	addi	zero,zero,7
	addi	zero,zero,8

	ecall

	beq	zero,zero,1b

	addi	zero,zero,9
	addi	zero,zero,10

einde:	j einde

	.word 0xffffffff
	.word 0xffffffff

Universal_Handler:
	nop
	nop
	nop
	csrr a0,mip
	mret
#	j Universal_Handler

.option pop

  .size  _start, .-_start
