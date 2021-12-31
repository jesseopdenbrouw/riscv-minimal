#include <stdio.h>

volatile char str[60] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

volatile int i = 1234;

volatile double j = 1.2;

volatile unsigned long long int k = 0x7fffffffffff;

int main(void)
{
	sprintf(str, "| %d | %f | %llu |", i, j, k);
}

