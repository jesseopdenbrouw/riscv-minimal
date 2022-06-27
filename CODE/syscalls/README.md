# syscalls

This is an implementation of common system calls
for RISC-V bare metal processors.

# Supported system calls

`_sbrk` - get dynamic memory, used by `malloc` et al.

`_read` - read from device.

`_write` - write to device.

`_gettimeofday` - get time since last reset.

`_times` - get time since last reset in microseconds.

`_exit` - halt the program (endless loop).

Other system calls are not implemented and return
an error.

