CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: qsort

qsort: qsort.c
	$(CC) -O2 -g -o qsort qsort.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec qsort qsort.srec
	$(SREC2VHDL) -wf0 qsort.srec qsort.vhd
clean:
	rm -f qsort qsort.srec qsort.vhd
