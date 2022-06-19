/*
 * Bootloader startup file for RISC-V bare metal processor
 *
 * (c) 2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 *
 * */

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

/* bss and rom data copy with pointers
 * in registers. Faster code, but less
 * visible in RAM variables */
#define WITH_REGISTER

/* Import symbols from the linker */
extern uint8_t _sbss, _ebss;
extern uint8_t _sdata, _edata;
extern uint8_t _start_of_rom_to_copy;
extern uint8_t _srodata, _erodata;

/* Declare functions */
void __libc_init_array(void);
int main(void);
void pre_init_universal_handler(void);

/* The startup code must be placed at the begin of the ROM */
/* and doesn't need a stack frame of pushed registers */
/* The linker will place this function at the beginning */
/* of the code (text) */
__attribute__((section(".text.start_up_code_c")))
__attribute__((naked))
void _start(void)
{

	/* These assembler instructions set up the Global Pointer
	 * and the Stack Pointer and set the mtvec to the start
	 * address of the pre-int interrupt handler. This will
	 * catch pre-init interrupt. Mostly because of a bug. */
        __asm__ volatile (".option push;"
			  ".option norelax;"
	                  "la    gp, __global_pointer$;"
			  "la    sp, __stack_pointer$;"
                          "la    t0, pre_init_universal_handler;"
                          "csrw  mtvec,t0;"
			  ".option pop"
                      : /* output: none */
                      : /* input: none */
                      : /* clobbers: none */);

#ifdef WITH_REGISTER
	register uint8_t *pStart;
	register uint8_t *pEnd;
	register uint8_t *pdRom;
#else
	volatile uint8_t *pStart;
	volatile uint8_t *pEnd;
	volatile uint8_t *pdRom;
#endif

	/* Initialize the bss with 0 */
	pStart = &_sbss;
	pEnd = &_ebss;
	while (pStart < pEnd) {
		*pStart = 0x00;
		*pStart++;
	}

	/* Copy the ROM-placed RAM init data to the RAM */
	pStart = &_sdata;
       	pEnd = &_edata;
	pdRom = &_start_of_rom_to_copy;
	while (pStart < pEnd) {
		*pStart = *pdRom;
		pStart++;
		pdRom++;
	}

        /* Initialize the C library */
	// __libc_init_array();

	/* Just call main and stop */
	//exit(main());
	main();
	while (1);
}

/* Catch traps */
__attribute__((interrupt))
void pre_init_universal_handler(void)
{
	while (1);
}
