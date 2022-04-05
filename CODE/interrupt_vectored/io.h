#ifndef _IO_H
#define _IO_H

#include <stdint.h>


/* Base address of the I/O */
#define IO_BASE (0xf0000000UL)

/* General purpose I/O */
#define GPIOA_PIN  (*(volatile uint32_t*)(IO_BASE+0x00000000UL))
#define GPIOA_POUT (*(volatile uint32_t*)(IO_BASE+0x00000004UL))

typedef struct {
        volatile uint32_t PIN;
        volatile uint32_t POUT;
} GPIO_struct_t;

#define GPIOA_BASE (IO_BASE+0x00000000UL)

#define GPIOA ((GPIO_struct_t *) GPIOA_BASE)


/* USART (USART1) */
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


/* TIMER (TIMER1) */
typedef struct {
	volatile uint32_t CTRL;
	volatile uint32_t STAT;
	volatile uint32_t CNTR;
	volatile uint32_t CMPT;
} TIMER_struct_t;

#define TIMER1_BASE (IO_BASE+0x00000080UL)
#define TIMER1 ((TIMER_struct_t *) TIMER1_BASE)


/* RISC-V system timer (in I/O) */
#define TIME (*(volatile uint32_t*)(IO_BASE+0x000000f0UL))
#define TIMEH (*(volatile uint32_t*)(IO_BASE+0x000000f4UL))
#define TIMECMP (*(volatile uint32_t*)(IO_BASE+0x000000f8UL))
#define TIMECMPH (*(volatile uint32_t*)(IO_BASE+0x000000fcUL))

typedef struct {
	volatile uint32_t time;
	volatile uint32_t timeh;
} TIME_struct_t;

typedef struct {
	volatile uint32_t timecmp;
	volatile uint32_t timecmph;
} TIMECMP_struct_t;

#endif
