CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: basel_problem

basel_problem: basel_problem.c
	$(CC) -O0 -g -o basel_problem basel_problem.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c -lm
	$(OBJCOPY) -O srec basel_problem basel_problem.srec
	$(SREC2VHDL) -wf0 basel_problem.srec basel_problem.vhd
clean:
	rm -f basel_problem basel_problem.srec basel_problem.vhd
