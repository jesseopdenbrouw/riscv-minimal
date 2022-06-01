
/*
 * Inline routines for interrupt handling
 *
 * (c) 2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 */

#ifndef _INTERRUPT_H
#define _INTERRUPT_H

#include <stdint.h>

#define TRAP_DIRECT_MODE (0)
#define TRAP_VECTORED_MODE (1)

/* Enable the global IRQ */
#define enable_irq() \
	__asm__ volatile (".option push;" \
			  ".option norelax;" \
		          "li    t0, (1<<3)|(3<<11);" \
                          "csrw  mstatus,t0;" \
			  ".option pop" \
                          ::: "t0");

/* Disable the global IRQ */
#define disable_irq() \
	__asm__ volatile (".option push;" \
			  ".option norelax;" \
		          "li    t0, (3<<11);" \
                          "csrw  mstatus,t0;" \
			  ".option pop" \
                          ::: "t0");

/* Get start address of jump table (vectored) or handler (direct) */
#define get_mtvec() ({ uint32_t __tmp; \
	__asm__ volatile ("csrr %0, mtvec" : "=r"(__tmp)); \
	__tmp; })

/* Set the mtvec CSR, using mode TRAP_DIRECT_MODE or TRAP_VECTORED_MODE */
#define set_mtvec(VECTOR, MODE) \
  	__asm__ volatile (".option push;" \
                          ".option norelax;" \
                          "la    t0, " #VECTOR ";" \
                          "csrw  mtvec,t0;" \
                          ".option pop" \
			  ::: "t0"); \
	if (MODE == TRAP_VECTORED_MODE) { \
		__asm__ volatile (".option push;" \
				  ".option norelax;" \
				  "csrsi mtvec,1;" \
                          	  ".option pop" \
			  	  ::: ); \
	}

#endif
