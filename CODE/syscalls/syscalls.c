#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>

/* These are system call stubs. The user can implement
 * these. By default, the system calls return 0 or
 * an error. Global errno can be checked. */

/* Only _sbrk is implemented to facilitate malloc()
 * and friends. */

/* User callable functions */
__attribute__((weak)) int __io_putchar(int ch) {
	return 0;
}

__attribute__((weak)) int __io_getchar(void) {
	return 0;
}


int _read(int fd, char *buf, int n) {

	for (int i = 0; i < n; i++) {
		*buf++ = __io_getchar();
	}
	return n;
}

int _write(int fd, char* buf, int n) {

	for (int i = 0; i < n; i++) {
		__io_putchar(*buf++);
	}
	return n;
}

int _getpid(void) {
	return 1;
}

int _kill(int pid, int sig) {
	errno = EINVAL;
	return -1;
}

int _close(int file) {
	return -1;
}


int _fstat(int file, struct stat *st) {
	st->st_mode = S_IFCHR;
	return 0;
}

int _isatty(int file) {
	return 1;
}

int _lseek(int file, int ptr, int dir) {
	return 0;
}

int _open(char *path, int flags, ...) {
	return -1;
}

int _wait(int *status) {
	errno = ECHILD;
	return -1;
}

int _unlink(char *name) {
	errno = ENOENT;
	return -1;
}

int _times(struct tms *buf) {
	return -1;
}

int _stat(char *file, struct stat *st) {
	st->st_mode = S_IFCHR;
	return 0;
}

int _link(char *old, char *new) {
	errno = EMLINK;
	return -1;
}

int _fork(void) {
	errno = EAGAIN;
	return -1;
}

int _execve(char *name, char **argv, char **env) {
	errno = ENOMEM;
	return -1;
}

/* _sbrk must be provided to accomodate malloc et. al. */
static uint8_t *__sbrk_heap_end = NULL;

void *_sbrk(ptrdiff_t incr)
{
	extern uint8_t _end; /* Symbol defined in the linker script */
	extern uint8_t __stack_pointer$; /* Symbol defined in the linker script */
	extern uint32_t __stack_size; /* Symbol defined in the linker script */
	const uint32_t stack_limit = (uint32_t)&__stack_pointer$ - (uint32_t)&__stack_size;
	const uint8_t *max_heap = (uint8_t *)stack_limit;
	uint8_t *prev_heap_end;

	/* Initialize heap end at first call */
	if (NULL == __sbrk_heap_end)
	{
		__sbrk_heap_end = &_end;
	}

	/* Protect heap from growing into the reserved stack space */
	if (__sbrk_heap_end + incr > max_heap)
	{
		errno = ENOMEM;
		return (void *)-1;
	}

	prev_heap_end = __sbrk_heap_end;
	__sbrk_heap_end += incr;

	return (void *)prev_heap_end;
}
