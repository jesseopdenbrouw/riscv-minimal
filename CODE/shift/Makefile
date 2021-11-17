CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: shift

shift: shift.c
	$(CC) -O0 -g -o shift shift.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/minimal.S
	$(OBJCOPY) -O srec shift shift.srec
	$(SREC2VHDL) -f shift.srec shift.vhd
clean:
	rm -f shift shift.srec shift.vhd
