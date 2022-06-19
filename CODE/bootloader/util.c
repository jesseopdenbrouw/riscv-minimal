#include <ctype.h>

#include "io.h"
#include "usart.h"

/* Parse hex string from s, ppchar return position after the hex string */
unsigned long int parsehex(char *s, char **ppchar) {

	unsigned long int v = 0;

	while (isspace((int) *s)) {
		s++;
	}

	while (isxdigit((int) *s)) {
		v <<= 4;
		if (isdigit((int) *s)) {
			v |= *s - '0';
		} else {
			v |= tolower(*s) - 'a' + 10;
		}
		s++;
	}

	if (ppchar != NULL) {
		*ppchar = s;
	}
	
	return v;
}

/* Print hex string, n is number of hex characters */
void printhex(unsigned long int v, int n) {
	char buf[9] = { 0 };

	if (n < 1 || n > 8) {
		n = 8;
	}
	for (int i = 0; i < n; i++) {
		unsigned char c = (v & 0x0f) + '0';
		if (c > '9') {
			c += 'a' - '0' - 10;
		}
		buf[n-1-i] = c;
		v >>= 4;
	}
	usart_puts(buf);
}

unsigned long int gethex(int n) {

	unsigned long int v = 0;
	
	for (int i = 0; i < n; i++) {
		int c = usart_getc();
		v <<= 4;
		if (isdigit(c)) {
			v |= c - '0';
		} else if (isxdigit(c)) {
			v |= tolower(c) - 'a' + 10;
		}
	}
	return v;
}
