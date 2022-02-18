#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <inttypes.h>
#include "io.h"

/* Frequency of the DE0-CV board */
#define F_CPU (50000000UL)
/* Transmission speed */
#define BAUD_RATE (9600ULL)

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
	int64_t sec, min, hour;
	struct timeval t;

	char buffer[100] = {0};

	usart_init();

	usart_puts("\r\n\r\nTime since last reset:\r\n");

	while (1) {
		gettimeofday(&t, NULL);

		sec = t.tv_sec % 60LL;

		min = (t.tv_sec / 60LL) % 60LL;

		hour = (t.tv_sec / 3600LL);

		snprintf(buffer, sizeof buffer, "%ld,%06ld | %03ld:%02ld:%02ld           \r", (int32_t) t.tv_sec, (int32_t)t.tv_usec, (int32_t)hour, (int32_t)min, (int32_t)sec);
		usart_puts(buffer);
	}
	return 0;
}
