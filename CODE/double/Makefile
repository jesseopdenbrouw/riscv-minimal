CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
SIZE = riscv32-unknown-elf-size

all: double test_double

double: double.c
	$(CC) -O2 -g -o double double.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c -lm
	$(OBJCOPY) -O srec double double.srec
	$(SREC2VHDL) -wf0 double.srec double.vhd
	$(SIZE) double

test_double: test_double.c
	gcc -o test_double test_double.c -lm


clean:
	rm -f double double.srec double.vhd test_double
