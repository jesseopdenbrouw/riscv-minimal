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

/* Get one character from the USART in
 * blocking mode */
int usart_getc(void)
{
	/* Wait for received character */
	while ((USART->STAT & 0x04) == 0);

	/* Return 8-bit data */
	return USART->DATA & 0x000000ff;
}

/* Gets a string terminated by a newline character from usart
 * The newline character is not part of the returned string.
 * The string is null-terminated.
 * A maximum of size-1 characters are read.
 * Some simple line handling is implemented */
int usart_gets(char buffer[], int size) {
	int index = 0;
	char chr;

	while (1) {
		chr = usart_getc();
		switch (chr) {
			case '\n':
			case '\r':	buffer[index] = '\0';
					usart_puts("\r\n");
					return index;
					break;
			/* Backspace key */
			case 0x7f:
			case '\b':	if (index>0) {
						usart_putc(0x7f);
						index--;
					} else {
						usart_putc('\a');
					}
					break;
			/* control-U */
			case 21:	while (index>0) {
						usart_putc(0x7f);
						index--;
					}
					break;
			/* control-C */
			case 0x03:  	usart_puts("<break>\r\n");
					index=0;
					break;
			default:	if (index<size-1) {
						if (chr>0x1f && chr<0x7f) {
							buffer[index] = chr;
							index++;
							usart_putc(chr);
						}
					} else {
						usart_putc('\a');
					}
					break;
		}
	}
	return index;
}

int main(void) {
	int j = 2;
	float k = 1.2f;
	double l = 0.6;

	char buffer[100] = { 0 };

	char *pc = buffer;

	usart_init();

	sprintf(buffer, "%d %p %.20f %.20f\r\n", j, pc, k, l);

	usart_puts(buffer);

	return 0;
}	
