/*
 * handlers.c -- exception and interrupt handlers
 *
 * (c) 2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>'
 *
 */

#include <stdint.h>

#include "io.h"
#include "usart.h"

#define CLOCK_FREQUENCY (1000000ULL)
#define INTERRUPT_FREQUENCY (10ULL)

static uint64_t external_timer_delta = (CLOCK_FREQUENCY/INTERRUPT_FREQUENCY);

/* Debugger stub, currenly halts in an endless loop.
 * The debugger function must NOT call any system
 * calls or trigger execptions. */
void debugger(uint32_t stack_pointer)
{
	/* You cannot use printf here as it uses ECALL */
	usart_puts("\r\nEBREAK! mip = ");

	register uint32_t mask = 0x80000000;
	register uint32_t mip;

	__asm__ volatile ("csrr %0, mip" : "=r"(mip) ::);

	while (mask) {
		usart_putc(mip & mask ? '1' : '0');
		mask >>= 1;
	}
	usart_puts("\r\n");
}

/* TIMER1 compare match T interrupt processing */
void timer1_cmpt_handler(void)
{
	/* Remove CMPT interrupt flag */
	TIMER1->STAT &= ~(1<<4);
	/* Flip output bit 0 (led) */
	GPIOA->POUT ^= 0x1;
}

/* The default handler, which holds the processor */
void default_hander(void)
{
	while(1);
}

/* The RISC-V external timer can be found in memory
 * mapped addresses in the I/O. Asserts an interrupt
 * when TIMECMPH:TIMECMP >= TIMEH:TIME. By writing
 * a greater number in TIMECMPH:TIMECMP, the
 * interrupt is negated. */
void external_timer_handler(void)
{
	/* Fetch current time */
	register uint64_t cur_time = ((uint64_t)TIMEH << 32) | (uint64_t)TIME;
	/* Add delta */
	cur_time += external_timer_delta;
	/* Set TIMECMP to maximum */
	TIMECMPH = -1;
	TIMECMP = -1;
	/* Store new TIMECMP */
	TIMECMP = (uint32_t)(cur_time & 0xffffffff);
	TIMECMPH = (uint32_t)(cur_time>>32);
	/* Flip output bit 1 (led) */
	GPIOA->POUT ^= 0x2;
}

/* USART receive and/or transmit handler */
void usart_handler(void)
{
	/* Test to see if character is received or transmitted.
	 * Test to see if there are any errors. */

	if (USART->STAT & 0x04) {
		GPIOA->POUT ^= 0x4;
		/* Clear all receive flags, discard data */
		USART->DATA;
	}

	/* Don't use USART->STAT = 0x00 otherwise the
	 * transmit complete flag can be written 0 just
	 * after transmit is really completed and the
	 * usart_putc() function will hang */
}
