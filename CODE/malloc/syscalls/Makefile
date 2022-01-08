#
# Makefile for creating the system call library
# for the RISC-V Minimal project.
# See: https://github.com/jesseopdenbrouw/riscv-minimal
#

CC = riscv32-unknown-elf-gcc
AR = riscv32-unknown-elf-ar

CFLAGS = -Wall -O2 -g -march=rv32i -mabi=ilp32

LIBSYS = libsyscalls.a
OBJ = syscalls.o sys_gettimeofday.o sys_sbrk.o sys_exit.o sys_read_write.o sys_times.o sys_env.o

all: $(LIBSYS) 

$(LIBSYS): $(OBJ)
	$(AR) -srv $(LIBSYS) $(OBJ)

%o: %c
	$(CC) -c $< -o $@

clean:
	rm -f $(OBJ) $(LIBSYS)
