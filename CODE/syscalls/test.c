#include <stdio.h>
#include <unistd.h>
#include <malloc.h>

int main(void)
{
	volatile char *p;
       
	p = malloc(100);

	p[0] = 'A';

	write(1, "Hallo", 5);

	volatile float pi = 3.14159f;
	pi = 10.0f*pi;

	pi = pi / 100.0f;

	return 0;
}
