#include <stdio.h>

volatile char str[30] = "AAAAAAAAAAAAA";

volatile int i = 1234;

volatile double j = 1.2;

int main(void)
{
	sprintf(str, "%d %f", i, j);
}

