#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>

/* System call stub for _times */

int _times(struct tms *buf) {
	return -1;
}
