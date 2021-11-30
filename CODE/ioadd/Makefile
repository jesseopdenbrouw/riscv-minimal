CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: ioadd

ioadd: ioadd.c io.h
	$(CC) -O2 -g -o ioadd ioadd.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/minimal.S
	$(OBJCOPY) -O srec ioadd ioadd.srec
	$(SREC2VHDL) -wf ioadd.srec ioadd.vhd
clean:
	rm -f ioadd ioadd.srec ioadd.vhd
