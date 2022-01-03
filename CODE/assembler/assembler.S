
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
/*

        la  x1, _start
	la  x2, _start_ram
	lw  x4, 4(x1);
	sw  x4, 0(x2)

	lw  x5, 0(x2)

halt:   addi x0,x0,0
	addi x0,x0,1
	addi x0,x0,2

	rdcycle a0
	rdcycleh a1

	li x9,0x11111111
	csrrw	x11,3103,x9
	csrrw	x11,3103,x0
	csrrwi	x11,3103,31

*/
	li      x4,0x21
	li	x3,0x10
	mul	x5,x4,x3
	rem	x5,x4,x3
einde:	j einde


.option pop

  .size  _start, .-_start
