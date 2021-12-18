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

	while (isspace((int) *s)) {
		s++;
	}

	if (*s == '\0') {
		return 0;
	}

	while (*s != '\0' && *s != ' ') {
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

uint32_t read_data_after_address(char *s) {

	uint32_t val = 0;

	while (isspace((int) *s)) {
		s++;
	}
	if (*s == '\0') {
		return 0;
	}
	while (!isspace((int) *s)) {
		s++;
	}
	while (isspace((int) *s)) {
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
	int little = 1;

	usart_init();

	usart_puts("\r\nTHUAS RISC-V FPGA 32-bit processor\r\n");
	usart_puts("Monitor v0.1\r\n");

	while (1) {

		usart_puts(">> ");
		usart_gets(buffer, sizeof buffer);
		len = strlen(buffer);
		if (len == 0) {
			usart_puts("Enter a command\r\n");
			continue;
		}

		if (len == 1) {
			if (buffer[0] == 'h') {
				usart_puts("Commands:\r\n");
				usart_puts("h -- this help\r\n");
				usart_puts("l -- set little endian format\r\n");
				usart_puts("b -- set big endian format\r\n");
				usart_puts("rw <address> -- read word\r\n");
				usart_puts("rh <address> -- read half word\r\n");
				usart_puts("rb <address> -- read byte\r\n");
				usart_puts("ww <address> <data> -- write word\r\n");
				usart_puts("wh <address> <data> -- write half word\r\n");
				usart_puts("wb <address> <data> -- write byte\r\n");
				continue;
			}
			if (buffer[0] == 'b') {
				usart_puts("Set Big Endian\r\n");
				little = 0;
				continue;
			}
			if (buffer[0] == 'l') {
				usart_puts("Set Little Endian\r\n");
				little = 1;
				continue;
			}
				
		}

		if (len < 3) {
			usart_puts("Enter a correct command\r\n");
			continue;
		}

		if (buffer[0] == 'r') {
			if (buffer[1] == 'w') {
				uint32_t *p = (uint32_t *) read_address(buffer+2);
				if (((uint32_t)p & 3) == 0) {
					uint32_t val = *p;
					if (little) {
						val = ((val & 0xff) << 24) + (((val >> 8) & 0xff) << 16) + (((val >> 16) & 0xff) << 8) + ((val >> 24) & 0xff);
					}
					sprintf(buffer, "%08lx", val);
					usart_puts(buffer);
				} else {
					usart_puts("Not on 4-byte boundary");
				}
			} else if (buffer[1] == 'h') {
				uint16_t *p = (uint16_t *) read_address(buffer+2);
				if (((uint32_t)p & 1) == 0) {
					uint16_t val = *p;
					if (little) {
						val = ((val & 0xff) << 8) + ((val >> 8) & 0xff);
					}
					sprintf(buffer, "%04lx", (uint32_t) val);
					usart_puts(buffer);
				} else {
					usart_puts("Not on 2-byte boundary");
				}
			} else if (buffer[1] == 'b') {
				uint8_t *p = (uint8_t *) read_address(buffer+2);
				uint8_t val = *p;
				sprintf(buffer, "%02lx", (uint32_t) val);
				usart_puts(buffer);
			} else {
				usart_puts("Unknown size");
			}
			usart_puts("\r\n");
		}

		if (buffer[0] == 'w') {
			if (buffer[1] == 'w') {
				volatile uint32_t *p = (uint32_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				if (((uint32_t)p & 3) == 0) {
					*p = data;
				} else {
					usart_puts("Not on 4-byte boundary");
				}
			} else if (buffer[1] == 'h') {
				volatile uint16_t *p = (uint16_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				if (((uint32_t)p & 1) == 0) {
					*p = (uint16_t) data;
				} else {
					usart_puts("Not on 2-byte boundary");
				}
			} else if (buffer[1] == 'b') {
				volatile uint8_t *p = (uint8_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				*p = (uint8_t) data;
			} else {
				usart_puts("Unknown size");
			}
			usart_puts("\r\n");
		}
	}

	return 0;
}
