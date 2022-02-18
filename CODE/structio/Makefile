CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: structio

structio: structio.c ios.h
	$(CC) -O2 -g -o structio structio.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec structio structio.srec
	$(SREC2VHDL) -wf0 structio.srec structio.vhd
clean:
	rm -f structio structio.srec structio.vhd
