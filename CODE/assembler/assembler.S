
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

	.word 0xfffefdfc
	.word 0xbfbebdbc
	.word 0xafaeadac
	.word 0x9f9e9d9c
