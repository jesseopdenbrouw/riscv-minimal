#include <stdint.h>

#include "io.h"

int main(void) {
	volatile uint32_t *input = (uint32_t *) GPIO_DATAIN_ADDR;
	volatile uint32_t *output = (uint32_t *) GPIO_DATAOUT_ADDR;

	while (1) {
		*output = *input;
	}
}
