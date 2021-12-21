
# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax


	la gp, __global_pointer$
        la sp, __stack_pointer$ 

        la  x1, _start
	la  x2, _start_ram
	lw  x4, 4(x1);
	sw  x4, 0(x2)

	lw  x5, 0(x2)

halt:   addi x0,x0,0
	addi x0,x0,1
	addi x0,x0,2

	beq x0,x0,halt

	addi x0,x0,3
	addi x0,x0,4
	addi x0,x0,5

	# Not supported (yet)
	mulh x1,x2,x3
	mul x1,x2,x3

	# Not supported yet
	rdtime x1
	rdcycle x2

einde:	j einde


.option pop

  .size  _start, .-_start
