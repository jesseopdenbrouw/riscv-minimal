

#ifndef _USART_H
#define _USART_H

/* Initialize the USART */
void usart_init(void);
/* Write one character to USART */
void usart_putc(int ch);
/* Write null-terminated string to USART */
void usart_puts(char *s);
/* Get one character from USART */
int usart_getc(void);
/* Check if character is received */
int usart_received(void);
/* Get maximum size-1 characters in string buffer from USART */
int usart_gets(char buffer[], int size);

#endif
