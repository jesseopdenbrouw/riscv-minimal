#
# Makefile for creating the system call library
# for the RISC-V Minimal project.
# See: https://github.com/jesseopdenbrouw/riscv-minimal
#

CC = riscv32-unknown-elf-gcc
AR = riscv32-unknown-elf-ar

CFLAGS = -Wall -O2 -g -march=rv32im -mabi=ilp32

OBJ = startup.o

all: $(OBJ) 

%.o: %.c
	$(CC) -c $< -o $@

clean:
	rm -f $(OBJ)
