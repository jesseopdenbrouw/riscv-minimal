CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: testio

testio: testio.c io.h
	$(CC) -O2 -g -o testio testio.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/minimal.S
	$(OBJCOPY) -O srec testio testio.srec
	$(SREC2VHDL) -wf testio.srec testio.vhd
clean:
	rm -f testio testio.srec testio.vhd
