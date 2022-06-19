
#ifndef _UTIL_H_
#define _UTIL_H_

/* Parse hex number from string */
unsigned long int parsehex(char *s, char **ppchar);
/* Print hex number to USART */
void printhex(unsigned long int v, int n);
/* Get a hex number from the USART */
unsigned long int gethex(int n);


#endif
