CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: string

string: string.c
	$(CC) -O0 -g -o string string.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c ../crt/startup.S
	$(OBJCOPY) -O srec string string.srec
	$(SREC2VHDL) -f string.srec string.vhd
clean:
	rm -f string string.srec string.vhd
