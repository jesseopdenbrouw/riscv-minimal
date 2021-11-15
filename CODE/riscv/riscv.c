#include <stdio.h>
#include <string.h>

/* Initialized */
unsigned long int x = 0xffffffff;

/* Uninitilized, defaults to 0x0 */
unsigned long long int z;

/* A constant */
const long int w = 0x12345678;

char str[] = "Hallo";

int main(void) {

	x = strlen(str);
	x++;
	z = 0xffffffff;

	//puts("Hello\n");

	return 0;
}

