/*
 * program to test trigoniometry functions
 * on the processor. Due to large ROM contents
 * we need to select the functions used.
 *
 */

#include <math.h>
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

int main(void)
{
	char buffer[60];

	volatile float x;
	volatile float w = 1.0f;

	usart_init();

	usart_puts("Some float and double math calculations\r\n");

	x = sinf(w);

	sprintf(buffer, "sinf(%f) = %.10f\r\n", w, x);
	usart_puts(buffer);

	x = asinf(w);

	sprintf(buffer, "asinf(%f) = %.10f\r\n", w, x);
	usart_puts(buffer);

	x = logf(w);

	sprintf(buffer, "logf(%f) = %.10f\r\n", w, x);
	usart_puts(buffer);

	volatile double y = 1.0;
	volatile double z;

	z = sin(y);

	sprintf(buffer, "sin(%f) = %.20f\r\n", w, z);
	usart_puts(buffer);

	z = asin(y);

	sprintf(buffer, "asin(%f) = %.20f\r\n", w, z);
	usart_puts(buffer);

	z = tan(w);

	sprintf(buffer, "tan(%f) = %.20f\r\n", w, z);
	usart_puts(buffer);

	z = log(y);

	sprintf(buffer, "log(%f) = %.20f\r\n", w, z);
	usart_puts(buffer);

	return 0;
}
