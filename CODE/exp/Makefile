CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
SIZE = riscv32-unknown-elf-size

all: exp

exp: exp.c
	$(CC) -O2 -g -o exp exp.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec exp exp.srec
	$(SREC2VHDL) -wf0 exp.srec exp.vhd
	$(SIZE) exp
clean:
	rm -f exp exp.srec exp.vhd
