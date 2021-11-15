CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: mult

mult: mult.c
	$(CC) -O2 -g -o mult mult.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c ../crt/startup.S
	$(OBJCOPY) -O srec mult mult.srec
	$(SREC2VHDL) -f mult.srec mult.vhd
clean:
	rm -f mult mult.srec mult.vhd
