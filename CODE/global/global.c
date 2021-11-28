#include <errno.h>

//int x = 0;
//int y = 0;

int ary[20] = { 2, 4, 5, 6, 9};

int x = 0xffff;

int y;

int main(void) {

	errno = -1;

	char buf[20];

	_read(0, buf, 1);

//	x = x + 2;
//	y = y + 3;

	return 0;
}
