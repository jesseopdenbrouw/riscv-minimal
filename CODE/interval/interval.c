#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <inttypes.h>

#include "io.h"

/* Frequency of the DE0-CV board */
#define F_CPU (50000000UL)
/* Transmission speed */
#define BAUD_RATE (9600UL)

/* Initialize the Baud Rate Generator */
void usart_init(void)
{
        /* Set baud rate generator */
        USART->BAUD = F_CPU/BAUD_RATE-1;
}

/* Send one character over the USART */
void usart_putc(int ch)
{
        /* Transmit data */
        USART->DATA = (uint8_t) ch;

        /* Wait for transmission end */
        while ((USART->STAT & 0x10) == 0);
}

/* Send a null-terminated string over the USART */
void usart_puts(char *s)
{
        if (s == NULL)
        {
                return;
        }

        while (*s != '\0')
        {
                usart_putc(*s++);
        }
}

int main(void)
{

	char buffer[100] = {0};

	usart_init();

	usart_puts("\r\n\r\nInterval testing\r\n");

	snprintf(buffer, sizeof buffer, "Clocks per second: %d\r\n", CLOCKS_PER_SEC);
	usart_puts(buffer);

	if (CLOCKS_PER_SEC != 1000000) {
		usart_puts("Clocks per second should be 1000000!\r\n");
	}

	while (1) {

		clock_t current = clock();

		snprintf(buffer, sizeof buffer, "%lu\r\n", current);
		usart_puts(buffer);

		usart_puts("Wait....\r");

		while (clock() - current < 5*CLOCKS_PER_SEC);

		usart_puts("5 seconds elapsed\r\n");
	}
	return 0;
}
