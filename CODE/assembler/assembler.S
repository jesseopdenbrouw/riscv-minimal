
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

	la gp, __global_pointer$
        la sp, __stack_pointer$ 

	la t0,handler
	csrw mtvec,t0
        li t0, 0x8 | (0x3<<11)
        csrw mstatus,t0

	li	x10,0x20000000
	li      x11,0x00000333
	div	x12,x10,x11

	nop
	nop
	nop

einde:	j einde

	.word 0xffffffff
	.word 0xffffffff
	.word 0xffffffff
	.word 0xffffffff

handler: 
	nop
	la	x4,0xf0000000
	lw	x5,4(x4)
	xori	x5,x5,5
	sw	x5,4(x4)
	 mret

.option pop

  .size  _start, .-_start
