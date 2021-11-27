#include <stdio.h>
#include <string.h>

int main(void) {

	/* The strinfg */
	char str[] = "Hello dit is een string";

	/* Make a non-volatile buffer */
	volatile char to[100];

	/* Get the string length */
	volatile int x = strlen(str);

	/* Copy the string */
	strcpy(to, str);

	/* Get string compare */
	x = strcmp("Hello", str);

	return x;
}
