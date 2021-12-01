


#ifndef _IO_H
#define _IO_H

#include <stdint.h>

#define IO_BASE (0xf0000000UL)

#define GPIOA_PIN (*(volatile uint32_t*)(IO_BASE+0x00000000UL))
#define GPIOA_POUT (*(volatile uint32_t*)(IO_BASE+0x00000004UL))

#endif
