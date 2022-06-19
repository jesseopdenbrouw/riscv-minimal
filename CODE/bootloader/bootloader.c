/*
 *
 * bootloader.c -- a simple bootloader for THUAS RISC-V
 *
 * (c)2022, J.E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl
 *
 */

/* NOTE:
 * DO NOT USE ANY SYSTEM CALLS
 * DO NOT USE FUNCTIONS THAT TRIGGER SYSTEM CALLS
 * (malloc et al, printf et al, times et al)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "io.h"
#include "usart.h"
#include "util.h"

#define VERSION "v0.1"
#define BUFLEN (41)
#define BOOTWAIT (10)

int main(void) {

	/* Start address of application */
	void (*app_start)(void) = (void *) 0x00000000;
	/* Buffer for commands */
	char buffer[BUFLEN];
	/* Used in initial delay */
	int count;
	/* Used to test on key hit */
	int keyhit = 0;
	/* */
	unsigned char c;
	/* Address */
	unsigned long addr = 0;


	/* Initialize USART at 9600 bps */
	usart_init();

	/* Send greeting */
	usart_puts("\r\nTHUAS RISC-V Bootloader " VERSION "\r\n");

	/* Wait a short while for a key hit */
	GPIOA->POUT = (1<<BOOTWAIT)-1;
	for (count = 1; count <= BOOTWAIT*1024*1024; count++) {
		/* Modulo power of 2 save a rem instruction */
		if (count % (1024*1024) == 0) {
			usart_putc('*');
			GPIOA->POUT >>= 1;
		}
		if (usart_received()) {
			keyhit = 1;
			break;
		}
	}
	GPIOA->POUT = 0;

	/* If no key was hit with the time frame,
	 * start the application */
	if (!keyhit) {
		(*app_start)();
	}

	/* Check the entered character */
	/* If it is a ! then enter file upload */
	if (usart_getc() == '!') {
		/* Send acknowledge */
		usart_puts("?\n");
		while (1) {
			/* Read in 'S' */
			GPIOA->POUT ^= 0x01;
			c = usart_getc();
			if (c == 'S') {
				/* Read in record type */
				c = usart_getc();
				/* Type 1, 2, 3 is data record */
				if (c == '1' || c == '2' || c == '3') {
					/* Get count, read start address and ignore check byte */
					unsigned long count;
					unsigned long v;
					if (c == '1') {
						count = gethex(2) - 3;
						v = gethex(4);
					} else if (c == '2') {
						count = gethex(2) - 4;
						v = gethex(6);
					} else {
						count = gethex(2) - 5;
						v = gethex(8);
					}
					/* Process bytes */
					for (unsigned long i = 0; i < count; i++) {
						/* Set address, get byte and word data */
						volatile unsigned long *boun = (unsigned long *) (v & ~3);
						volatile unsigned long byte = gethex(2);
						volatile unsigned long word = *boun;

						/* Patch the byte in the word */
						switch (v & 3) {
							case 0: word = (word & ~0xffUL) | byte;
								break;
							case 1: word = (word & ~0xff00UL) | (byte << 8);
								break;
							case 2: word = (word & ~0xff0000UL) | (byte << 16);
								break;
							case 3: word = (word & ~0xff000000UL) | (byte << 24);
								break;
							default:
								break;
						}
						/* Write back the word */
						*boun = word;
						v++;
					}
					/* Read in rest of line */
					while ((c = usart_getc()) != '\n');
				} else
				/* Type 7, 8, 9 is end record with start address */
				if (c == '7' || c == '8' || c == '9') {
					/* Skip count */
					unsigned long v = gethex(2);
					/* Read in start address */
					if (c == '7') {
						v = gethex(8);
					} else if (c == '8') {
						v = gethex(6);
					} else {
						v = gethex(4);
					}
					/* Read in rest of line */
					while ((c = usart_getc()) != '\n');
					/* Set start address */
					app_start = (void *) v;
				} else {
					/* Eat up line */
					while ((c = usart_getc()) != '\n');
				}
			} else if (c == 'J') {
				/* Start application after upload */
				USART->BAUD = 0;
				GPIOA->POUT = 0;
				(*app_start)();
				break;
				/* Break to bootloader */
			} else if (c == '#') {
				break;
			}
			usart_puts("?\n");
		}
		/* Signal reception complete */
		GPIOA->POUT = 0xaa;
	}

	/* Start the simple monitor */
	usart_puts("\r\n");

	while (1) {

		/* Send prompt and read input */
		usart_puts("> ");
		usart_gets(buffer, BUFLEN);

		int len = strlen(buffer);

		if (strcmp(buffer, "h") == 0) {
			/* Print help */
			usart_puts("Help:\r\n"
				   " h                - this help\r\n"
				   " r                - run application\r\n"
				   " rw <addr>        - read word from addr\r\n"
				   " ww <addr> <data> - write data at addr\r\n"
				   " dw <addr>        - dump 16 words\r\n"
				   " n                - dump next 16 words"
				  );
		} else if (strcmp(buffer, "r") == 0) {
			/* Start the application */
			USART->BAUD = 0;
			GPIOA->POUT = 0;
			(*app_start)();
		} else if (strncmp(buffer, "rw ", 3) == 0) {
			/* Read word */
			unsigned long v;
			addr = parsehex(buffer+3, NULL);
			if ((addr & 0x3) == 0) {
				printhex(addr,8);
				usart_puts(": ");
				v = *(unsigned long *) addr;
				printhex(v,8);
			} else {
				usart_puts("Not on 4-byte boundary!");
			}
		} else if (strncmp(buffer, "ww ", 3) == 0) {
			/* Write word */
			char *s;
			unsigned long v;
			addr = parsehex(buffer+3, &s);
			if ((addr & 0x3) == 0) {
				v = parsehex(s, NULL);
				*(unsigned long *) addr = v;
			} else {
				usart_puts("Not on 4-byte boundary!");
			}
		} else if ((strncmp(buffer, "dw ", 3) == 0) || (buffer[0] == 'n')) {
			/* Dump 16 words */
			unsigned long v, mask;
			if (buffer[0] != 'n') {
				addr = parsehex(buffer+3, NULL);
			}
			int c;
			if ((addr & 0x3) == 0) {
				for (int i = 0; i < 16; i++) {
					/* Iterate over 16 words */
					printhex(addr,8);
					usart_puts(": ");
					v = *(unsigned long *) addr;
					printhex(v,8);
					usart_puts("  ");
					/* Print ASCII code for bytes */
					mask = 0xff000000;
					for (int j = 3; j > -1; j--) {
						c = (v & mask) >> (j*8);
						if (isprint(c)) {
							usart_putc(c);
						} else {
							usart_putc('.');
						}
						mask >>= 8;
					}
					addr += 4;
					usart_puts("\r\n");
				}
			} else {
				usart_puts("Not on 4-byte boundary!");
			}
		} else if (len == 0) {
			/* do nothing */
		} else {
			usart_puts("??");
		}
		usart_puts("\r\n");
	}

	while(1);
}
