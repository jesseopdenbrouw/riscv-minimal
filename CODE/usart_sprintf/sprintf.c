#include <stdio.h>
#include <string.h>
#include <ctype.h>
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

int main(void) {

	int j = 2;
	float k = 1.2f;
	double l = 0.6;
	long long int m = 0x7fffffffffffffff;

	char buffer[100] = { 0 };

	char *pc = buffer;

	usart_init();

	sprintf(buffer, "%d %p %.20f %.20f %lld\r\n", j, pc, k, l, m);

	usart_puts(buffer);

	return 0;
}	
