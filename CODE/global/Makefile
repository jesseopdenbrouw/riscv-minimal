CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: global

global: global.c
	$(CC) -O0 -g -o global global.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec global global.srec
	$(SREC2VHDL) -wf0 global.srec global.vhd
clean:
	rm -f global global.srec global.vhd
