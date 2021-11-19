#include <string.h>

int main(void) {

	char str[] = "Hello dit is een string";

	volatile char to[100];

	volatile int x = strlen(str);

	strcpy(to, str);

	x = strcmp("Hello", str);

	return x;
}
