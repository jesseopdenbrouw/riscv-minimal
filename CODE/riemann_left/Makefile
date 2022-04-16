CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: riemann_left

riemann_left: riemann_left.c
	$(CC) -O0 -g -o riemann_left riemann_left.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c -lm
	$(OBJCOPY) -O srec riemann_left riemann_left.srec
	$(SREC2VHDL) -wf0 riemann_left.srec riemann_left.vhd
clean:
	rm -f riemann_left riemann_left.srec riemann_left.vhd
