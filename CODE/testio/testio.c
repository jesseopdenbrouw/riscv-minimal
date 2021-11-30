#include <stdint.h>

#include "io.h"

int main(void) {

	while (1) {
		GPIO_POUTA = GPIO_PINA;
	}
}
