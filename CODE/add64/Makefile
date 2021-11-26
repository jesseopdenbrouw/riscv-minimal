CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: add64

add64: add64.c
	$(CC) -O0 -g -o add64 add64.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec add64 add64.srec
	$(SREC2VHDL) -wf add64.srec add64.vhd
clean:
	rm -f add64 add64.srec add64.vhd
