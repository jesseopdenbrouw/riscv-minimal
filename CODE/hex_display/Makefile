CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: hex_display

hex_display: hex_display.c
	$(CC) -Os -g -o hex_display hex_display.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec hex_display hex_display.srec
	$(SREC2VHDL) -wf hex_display.srec hex_display.vhd
clean:
	rm -f hex_display hex_display.srec hex_display.vhd
