CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: startup_test

startup_test: startup_test.c
	$(CC) -O0 -g -o startup_test startup_test.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -nostartfiles --specs=nano.specs startup.c
	$(OBJCOPY) -O srec startup_test startup_test.srec
	$(SREC2VHDL) -wf0 startup_test.srec startup_test.vhd
clean:
	rm -f startup_test startup_test.srec startup_test.vhd
