#include <stdio.h>
#include <string.h>

#include "syscalls.h"

int main(void) {

	char str[30];

	_read(0, str, 1);

}
