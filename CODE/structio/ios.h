


#ifndef _IO_H
#define _IO_H

#include <stdint.h>

#define IO_BASE (0xf0000000UL)

typedef struct {
	volatile uint32_t PIN;
	volatile uint32_t POUT;
} GPIO_struct_t;

#define GPIOA_BASE (IO_BASE+0x00000000UL)

#define GPIOA ((GPIO_struct_t *) GPIOA_BASE)

#endif
