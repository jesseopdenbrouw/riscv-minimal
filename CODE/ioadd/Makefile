CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: ioadd

ioadd: ioadd.c io.h
	$(CC) -O2 -g -o ioadd ioadd.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec ioadd ioadd.srec
	$(SREC2VHDL) -wf0 ioadd.srec ioadd.vhd
clean:
	rm -f ioadd ioadd.srec ioadd.vhd
