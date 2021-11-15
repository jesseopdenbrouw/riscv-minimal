#include <stdint.h>

#include "io.h"

int main(void) {

	volatile uint32_t counter;

	while (1) {
		GPIO_DATAOUT = 0xffffffff;
		for (counter = 0; counter < 5000000; counter ++);
		GPIO_DATAOUT = ~GPIO_DATAOUT;
		for (counter = 0; counter < 5000000; counter ++);
	}
}
