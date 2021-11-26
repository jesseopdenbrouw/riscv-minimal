CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: assembler

assembler: assembler.S
	$(CC) -g -o assembler -Wall -T ../ldfiles/riscv.ld -march=rv32im -nostartfiles --specs=nano.specs assembler.S
	$(OBJCOPY) -O srec assembler assembler.srec
	$(SREC2VHDL) -wf assembler.srec assembler.vhd
clean:
	rm -f assembler assembler.srec assembler.vhd
