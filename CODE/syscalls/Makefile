CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
AR = riscv32-unknown-elf-ar

all: test

test: test.c syscalls.c
	$(CC) -O0 -g -o test test.c syscalls.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec test test.srec
	$(SREC2VHDL) -wf test.srec test.vhd
clean:
	rm -f test test.srec test.vhd
