// C program to sort integer array
// using qsort with function pointer

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int compare(const void* numA, const void* numB)
{
    const int* num1 = (const int*)numA;
    const int* num2 = (const int*)numB;

    if (*num1 > *num2) {
        return 1;
    }
    else {
        if (*num1 == *num2)
            return 0;
        else
            return -1;
    }
}

int main()
{
    volatile int arr[] = { 0x50, 0x30, 0x20, 0x10, 0x60, 0xa0, 0x40, 0xb0 };

    qsort(arr, sizeof arr / sizeof arr[0], sizeof(int), compare);

    return 0;
}
