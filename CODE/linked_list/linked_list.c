#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <malloc.h>
#include <string.h>

#include "io.h"


/* Frequency of the DE0-CV board */
#define F_CPU (50000000UL)
/* Transmission speed */
#define BAUD_RATE (9600ULL)


/* The stucture of the node */
#define NAMLEN (20)
typedef struct node
{
	char name[NAMLEN];
	int age;
	struct node *next;
} node_t;


node_t *head = NULL;


/* Initialize the Baud Rate Generator */
void usart_init(void)
{
        /* Set baud rate generator */
        USART->BAUD = F_CPU/BAUD_RATE-1;
}

/* Send one character over the USART */
void usart_putc(int ch)
{
        /* Transmit data */
        USART->DATA = (uint8_t) ch;

        /* Wait for transmission end */
        while ((USART->STAT & 0x10) == 0);
}

/* Send a null-terminated string over the USART */
void usart_puts(char *s)
{
        if (s == NULL)
        {
                return;
        }

        while (*s != '\0')
        {
                usart_putc(*s++);
        }
}


int main(void)
{
	/* Pointer to node */
	node_t *current, *prev;

	char buffer[NAMLEN+26];

	int count = 0;


	usart_init();

	usart_puts("\r\n\r\nLinked list test\r\n");

	sprintf(buffer, "Size of node: %u\r\n", sizeof(node_t));
	usart_puts(buffer);

	/* Create head (first) node */
	if ((head = malloc(sizeof(node_t))) == NULL) {
		usart_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Head node exists */
	strncpy(head->name, "Evan", NAMLEN);
	head->age = 25;
	head->next = NULL;

	/* Create new (second) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		usart_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Billie", NAMLEN);
	current->age = 18;
	current->next = NULL;

	/* Let head->next point to new node */
	head->next = current;
	/* Save current */
	prev = current;

	/* Create new (third) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		usart_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Sam", NAMLEN);
	current->age = 29;
	current->next = NULL;

	/* Let prev->next point to new node */
	prev->next = current;
	/* Save current */
	prev = current;

	/* Create new (fourth) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		usart_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Hendrik", NAMLEN);
	current->age = 54;
	current->next = NULL;

	/* Let prev->next point to new node */
	prev->next = current;
	/* Save current */
	prev = current;

	/* Print the list */
	for (current = head; current != NULL; current = current->next) {
		sprintf(buffer, "@: %p, name: %s, age: %d\r\n", current, current->name, current->age);
		usart_puts(buffer);
	}

	/* Find end of list */
	for (current = head; current != NULL; current = current->next) {
		prev = current;
	}
	/* prev points to the last node */
	
	sprintf(buffer, "Last node @: %p\r\n", prev);
	usart_puts(buffer);
	sprintf(buffer, "Name: %s, age: %d\r\n", prev->name, prev->age);
	usart_puts(buffer);

	/* Fill up all memory, but don't penetrate the stack */
	while (1) {
		prev = current;
		if ((current = malloc(sizeof(node_t))) == NULL) {
			usart_puts("Cannot allocate more nodes!\r\n");
			break;
		}
		count++;
	}

	sprintf(buffer, "Total of %d nodes\r\n", count);
	usart_puts(buffer);
	sprintf(buffer, "Last node @: %p\r\n", prev);
	usart_puts(buffer);

	return 0;
}
