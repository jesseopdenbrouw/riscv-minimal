CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: ctest

ctest: ctest.c
	$(CC) -O2 -g -o ctest -T ../ldfiles/riscv.ld -march=rv32i -nostartfiles --specs=nano.specs ctest.c ../crt/minimal.S
	$(OBJCOPY) -O srec ctest ctest.srec
	$(SREC2VHDL) -wf ctest.srec ctest.vhd

clean:
	rm -f ctest ctest.srec ctest.vhd
