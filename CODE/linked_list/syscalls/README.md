# System calls

This is a set of system calls. Most system calls
are not implemented and return an error.

The following system calls are placed in separate
files because they contribute considerable to the
code size of the executable.

The `_sbrk` system call is implemented because
`malloc()` et al. depend on it.

The `_read` and `_write` system calls are implemented.
They call `__io_getchar` and `__io_putchar` which
have to be implemented by the programmer. Typically
these functions call read and write function for the
USART.

The `_exit` system call is implemented and just
stops in an endless loop.

The `_gettimeofday` system call is implemented.
It returns the time in microseconds since last
reset.

The `_times` system returns the time in clock ticks
which is 1 us based.

## Status

Tested. Works.
