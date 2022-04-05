
/*
 * Inline routines for interrupt handling
 *
 * (c) 2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 */

#ifndef _INTERRUPT_H
#define _INTERRUPT_H

#include <stdint.h>

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

/* Set the address of the trap handler, direct (non vectored) */
#define set_mtvec(VECTOR) \
  	__asm__ volatile (".option push;" \
                          ".option norelax;" \
                          "la    t0, " #VECTOR ";" \
                          "csrw  mtvec,t0;" \
                          ".option pop" \
                          ::: "t0");

#define get_mtvec() ({ uint32_t __tmp; \
	__asm__ volatile ("csrr %0, mtvec" : "=r"(__tmp)); \
	__tmp; })

#endif
