#include <stdint.h>
#include <malloc.h>
#include <sys/time.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include "io.h"
#include "usart.h"
#include "interrupt.h"

/* Set to 1 to use printf(), uses system calls.
 * Set to 0 to use sprintf()/usart_puts(), doesn't
 * use system calls */
#define USE_PRINTF (0)

int main(int argc, char *argv[], char *envp[])
{
	struct timeval tv;
	uint32_t hour, min, sec;
	uint32_t ebreak_counter = 0;

#if USEPRINTF != 1
	char buffer[40] = {0};
#endif

	/* Set the trap handler vector */
	set_mtvec(universal_handler, TRAP_DIRECT_MODE);

	/* Initialize the USART*/
	usart_init();

	/* Activate TIMER1 with a cycle of 1 Hz */
	/* for a 50 MHz clock. Use interrupt. */
	TIMER1->CMPT = 24999999;
	/* Bit 0 = enable, bit 4 is interrupt enable */
	TIMER1->CTRL = (1<<4)|(1<<0);

	/* Enable mie.MTIE external timer interrupt */
	enable_external_timer_irq();

	/* Enable interrupts */
	enable_irq();

#if USEPRINTF == 1
	printf("\r\n");
	while(argc-- > 0) {
		printf("%s\r\n", *argv++);
	}
	printf("\r\n\r\nDisplaying the time passed since reset\r\n\r\n");
#else
	usart_puts("\r\n");
	while(argc-- > 0) {
		usart_puts(*argv++);
		usart_puts("\r\n");
	}
	usart_puts("\r\n\r\nDisplaying the time passed since reset\r\n\r\n");
#endif

	while (1) {
		/* Read in the time of the day */
		int status = gettimeofday(&tv, NULL);

		/* Produce hours, minutes and seconds */
		hour = tv.tv_sec / 3600UL;
		min = (tv.tv_sec / 60UL) % 60UL;
		sec = tv.tv_sec % 60UL;

		if (status == 0) {
#if USEPRINTF == 1
			printf("%05ld:%06ld", (int32_t) tv.tv_sec, tv.tv_usec);
			printf("   %02ld:%02ld:%02ld\r", hour, min, sec);
#else
			sprintf(buffer, "%05ld:%06ld   %02ld:%02ld:%02ld\r",
				(int32_t) tv.tv_sec, tv.tv_usec, hour, min, sec);
			usart_puts(buffer);
#endif
		}

		/* Once in every +/- 10 seconds, produce an EBREAK call */
		ebreak_counter++;
		if (ebreak_counter == 400) {
			ebreak_counter = 0;
			__asm__ volatile ("ebreak;" :::);
		}
	}

	return 0;
}
