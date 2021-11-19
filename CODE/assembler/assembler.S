
# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax


#	la gp, __global_pointer$
#        la sp, __stack_pointer$ 
#
#loop:   addi t0,t0,1     # Increment t0
#        slti t2,t0,10    # Set t2 to 1 is t0 < 10
#        j loop           # Jump to begin

#	 la t2,10
#         la t0,0
#
#loop:
#         addi t0,t0,1
#         bltu t0,t2,loop

        la  t1, _start_ram

        lw  t0, 0(zero)
        sw  t0, 0(t1)
        lw  t0, 4(zero)
        sw  t0, 4(t1)

        lw  t2, 0(t1)
	nop
        lw  t3, 4(t1)

halt:   j halt

       rdcycleH s0
       rdcycle  s1

       mul x3,x2,x1

.option pop

  .size  _start, .-_start
