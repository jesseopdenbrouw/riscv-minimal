CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: usart

usart: usart.c io.h
	$(CC) -O2 -g -o usart usart.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec usart usart.srec
	$(SREC2VHDL) -wf0 usart.srec usart.vhd
clean:
	rm -f usart usart.srec usart.vhd
