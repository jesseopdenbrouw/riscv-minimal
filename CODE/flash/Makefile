CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: flash

flash: flash.c io.h
	$(CC) -O2 -g -o flash flash.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/minimal.S
	$(OBJCOPY) -O srec flash flash.srec
	$(SREC2VHDL) -wf0 flash.srec flash.vhd
clean:
	rm -f flash flash.srec flash.vhd
