/*
 * Startup file for RISC-V bare metal processor
 *
 *
 *
 *
 * */

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

extern uint8_t _sbss, _ebss;
extern uint8_t _sdata, _edata;
extern uint8_t _start_of_rom_to_copy;
extern uint8_t _srodata, _erodata;

/* Declare the `main' function */
int main(void);

/* Declare the C library init function */
/* Declare the system init function */
#ifdef __cplusplus
extern "C" {
#endif
void __libc_init_array(void);
void _start(void);
#ifdef __cplusplus
}
#endif

/* The startup code must be placed at the begin of the ROM */
/* and doesn't need a stack frame of pushed registers */
/* The linker will place this function at the beginning */
/* of the code (text) */
__attribute__((section(".text.start_up_code_c")))
__attribute__((naked))
void _start(void)
{

	/* These assembler instructions set up the Global Pointer
	 * and the Stack Pointer. After that, the rest is C code */
        __asm__ volatile  (".option push;"
			   ".option norelax;"
	                   "la    gp, __global_pointer$;"
			   "la    sp, __stack_pointer$;"
			   ".option pop"
                      : /* output: none */
                      : /* input: none */
                      : /* clobbers: none */);

	volatile uint8_t *pStart = &_sbss;
	volatile uint8_t *pEnd = &_ebss;
	volatile uint8_t *pdRom = &_start_of_rom_to_copy;

	/* Initialize the bss with 0 */
	while (pStart < pEnd) {
		*pStart = 0x00;
		*pStart++;
	}

	/* Copy the ROM-placed RAM init data to the RAM */
	pStart = &_sdata;
       	pEnd = &_edata;
	while (pStart < pEnd) {
		*pStart = *pdRom;
		pStart++;
		pdRom++;
	}

        /* Initialize the C library */
        __libc_init_array();

	/* Just call main and stop */
	_exit(main());
}
