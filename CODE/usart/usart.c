#include "io.h"

/* Frequency of the DE0-CV board */
#define F_CPU (50000000UL)
/* Transmission speed */
#define BAUD (9600UL)

int main(void)
{

	/* Set baud rate generator */
	USART_BAUD = F_CPU/BAUD-1;

	/* Send a 'B' */
	USART_DATA = 0x62;

	/* Wait for transmission end */
	while ((USART_STAT & 0x10) == 0);

	/* Wait for received character */
	while((USART_STAT & 0x04) == 0);

	/* Put data on leds */
	GPIOA_POUT = USART_DATA;

	return 0;
}
