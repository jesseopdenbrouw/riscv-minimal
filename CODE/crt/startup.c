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

extern uint32_t _sbss, _ebss;
extern uint32_t _sdata, _edata;
extern uint32_t _start_of_rom_to_copy;

/* Declare the `main' function */
int main(void);

/* Declare the C library init function */
/* Declare the system init function */
#ifdef __cplusplus
extern "C" {
#endif
void __libc_init_array(void);
void _Initialize_System$(void);
#ifdef __cplusplus
}
#endif

/* The startup code must be placed at the begin of the ROM */
/* and doesn't need a stack frame of pushed registers */
__attribute__((section(".text.start_up_code_c")))
__attribute__((naked))
void _Initialize_System$(void)
{

//#ifndef __cplusplus
//	register
//#endif    
	volatile uint32_t *pStart = &_sbss;
	volatile uint32_t *pEnd = &_ebss;
	volatile uint32_t *pdRom = &_start_of_rom_to_copy;

	/* Initialize the bss with 0 */
	while (pStart < pEnd) {
		*pStart = 0x00000000;
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
//#ifndef __cplusplus
        __libc_init_array();
//#endif    

	/* Just call main */
	main();

	/* Stop */
	exit(0);
}
