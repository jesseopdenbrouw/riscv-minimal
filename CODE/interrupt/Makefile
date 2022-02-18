CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: interrupt

interrupt: interrupt.c
	$(CC) -O0 -g -o interrupt interrupt.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec interrupt interrupt.srec
	$(SREC2VHDL) -wf0 interrupt.srec interrupt.vhd
clean:
	rm -f interrupt interrupt.srec interrupt.vhd
