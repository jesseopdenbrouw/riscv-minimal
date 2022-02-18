#include "io.h"

/* Frequency of the DE0-CV board */
#define F_CPU (50000000UL)
/* Transmission speed */
#define BAUDRATE (9600UL)

int main(void)
{

	/* Set baud rate generator */
	USART->BAUD = F_CPU/BAUDRATE-1;

	/* Set two stop bits */
	USART->CTRL = 0x00;

	/* Read 8 switches from input */
	USART->DATA = GPIOA->PIN & 0x000000ff;

	/* Wait for transmission end */
	while ((USART->STAT & 0x10) == 0);

	/* Wait for received character */
	while ((USART->STAT & 0x04) == 0);

	/* Put data on leds */
	GPIOA->POUT = USART_DATA;

	return 0;
}
