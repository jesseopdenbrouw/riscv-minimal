CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
SIZE = riscv32-unknown-elf-size

all: float

float: float.c
	$(CC) -O2 -g -o float float.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec float float.srec
	$(SREC2VHDL) -wf0 float.srec float.vhd
	$(SIZE) float
clean:
	rm -f float float.srec float.vhd
