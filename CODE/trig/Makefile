CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
SIZE = riscv32-unknown-elf-size

all: trig test_double

trig: trig.c
	$(CC) -O2 -g -o trig trig.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ../crt/startup.c -lm
	$(OBJCOPY) -O srec trig trig.srec
	$(SREC2VHDL) -wf trig.srec trig.vhd
	$(SIZE) trig

test_double: test_double.c
	gcc -o test_double test_double.c -lm

clean:
	rm -f trig trig.srec trig.vhd test_double
