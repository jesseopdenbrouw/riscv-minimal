#include <stdint.h>

#include "io.h"

volatile uint32_t x;

int main(void) {

	volatile uint32_t *output = (uint32_t *) GPIO_DATAOUT;
	volatile uint32_t counter;

	x = x + 1;

	while (1) {
		for (counter = 0; counter < 5000000; counter ++);
		*output = 0xffffffff;
		for (counter = 0; counter < 5000000; counter ++);
		*output = 0x00000000;
	}
}
