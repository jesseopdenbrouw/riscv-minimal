CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
AR = riscv32-unknown-elf-ar

all: malloc

malloc: malloc.c syssbrk.c
	$(CC) -O0 -g -o malloc malloc.c syssbrk.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec malloc malloc.srec
	$(SREC2VHDL) -wf malloc.srec malloc.vhd
clean:
	rm -f malloc malloc.srec malloc.vhd
