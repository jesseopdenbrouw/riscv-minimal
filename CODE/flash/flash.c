#include <stdint.h>

#include "io.h"

int main(void) {

	volatile uint32_t counter;

	while (1) {
		GPIOA_POUT = 0xffffffff;
		for (counter = 0; counter < 5000000; counter ++);
		GPIOA_POUT = ~GPIOA_POUT;
		for (counter = 0; counter < 5000000; counter ++);
	}
}
