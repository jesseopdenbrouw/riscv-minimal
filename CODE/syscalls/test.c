#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <unistd.h>

#include "syscalls.h"

int main(void) {

	write(1, "Hallo", 5);

}
