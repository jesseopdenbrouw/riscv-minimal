CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: sprintf

sprintf: sprintf.c syssbrk.c
	$(CC) -O2 -g -o sprintf sprintf.c syssbrk.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c -u _printf_float
	$(OBJCOPY) -O srec sprintf sprintf.srec
	$(SREC2VHDL) -wf sprintf.srec sprintf.vhd
clean:
	rm -f sprintf sprintf.srec sprintf.vhd
