/*
 * handlers.h -- prototypes for handlers
 *
 * (c) 2022  Jesse E.J. op den Brouw
 *
 */

#ifndef _HANDLERS_H
#define _HANDLERS_H

/* Debugger */
void debugger(uint32_t stack_pointer);
/* TIMER1 compare match T interrupt */
void timer1_cmpt_handler(void);
/* External timer handler */
void external_timer_handler(void);
/* USART receive and/or transmit interrupt */
void usart_handler(void);

#endif
