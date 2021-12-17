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

/* Read a 32-bit address */
uint32_t read_address(char *s) {

	uint32_t val = 0;

	while (*s == ' ') {
		s++;
	}

	if (*s == '\0') {
		return 0;
	}

	while (*s != '\0') {
		if (isxdigit((int) *s)) {
			if (isdigit((int) *s)) {
				val = val*16 + *s - '0';
			} else {
				val = val*16 + toupper(*s) - 'A' + 10;
			}
		}
		s++;
	}

	return val;
}

int main(void)
{

	char buffer[40] = { 0 };
	int len;

	usart_init();

	usart_puts("THUAS RISC-V FPGA 32-bit processor\r\n");
	usart_puts("Monitor v0.1\r\n");

	while (1) {

		usart_gets(buffer, sizeof buffer);
		len = strlen(buffer);
		if (len == 0) {
			usart_puts("Enter a command\r\n");
			continue;
		}
		if (len < 3) {
			usart_puts("Enter a correct command\r\n");
			continue;
		}

		if (buffer[0] == 'r') {
			//usart_puts("Here\r\n");
			if (buffer[1] == 'w') {
				uint32_t *p = (uint32_t *) read_address(buffer+2);
				uint32_t val = *p;
				if ((uint32_t)p % 4 == 0) {
					sprintf(buffer, "%08lx", val);
					usart_puts(">> ");
					usart_puts(buffer);
				} else {
					usart_puts("Not on 4-byte boundary");
				}
				usart_puts("\r\n");
			} else if (buffer[1] == 'h') {
				uint16_t *p = (uint16_t *) read_address(buffer+2);
				uint32_t val = *p;
				if ((uint32_t)p % 2 == 0) {
					sprintf(buffer, "%04lx", val);
					usart_puts(">> ");
					usart_puts(buffer);
				} else {
					usart_puts("Not on 2-byte boundary");
				}
				usart_puts("\r\n");
			} else if (buffer[1] == 'b') {
				uint8_t *p = (uint8_t *) read_address(buffer+2);
				uint32_t val = *p;
				sprintf(buffer, "%02lx", val);
				usart_puts(">> ");
				usart_puts(buffer);
				usart_puts("\r\n");
			} else {
				usart_puts("Unknown size\r\n");
			}
		} else {
			usart_puts(buffer);
			usart_puts("\r\n");
		}
	}

	return 0;
}
