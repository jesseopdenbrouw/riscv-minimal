#ifndef _IO_H
#define _IO_H

#include <stdint.h>

#define IO_BASE (0xf0000000UL)

#define GPIOA_PIN  (*(volatile uint32_t*)(IO_BASE+0x00000000UL))
#define GPIOA_POUT (*(volatile uint32_t*)(IO_BASE+0x00000004UL))

typedef struct {
        volatile uint32_t PIN;
        volatile uint32_t POUT;
} GPIO_struct_t;

#define GPIOA_BASE (IO_BASE+0x00000000UL)

#define GPIOA ((GPIO_struct_t *) GPIOA_BASE)

#define USART_DATA (*(volatile uint32_t*)(IO_BASE+0x00000020UL))
#define USART_BAUD (*(volatile uint32_t*)(IO_BASE+0x00000024UL))
#define USART_CTRL (*(volatile uint32_t*)(IO_BASE+0x00000028UL))
#define USART_STAT (*(volatile uint32_t*)(IO_BASE+0x0000002CUL))

typedef struct {
	volatile uint32_t DATA;
	volatile uint32_t BAUD;
	volatile uint32_t CTRL;
	volatile uint32_t STAT;
} USART_struct_t;

#define USART_BASE (IO_BASE+0x00000020UL)

#define USART ((USART_struct_t *) USART_BASE)

#endif
