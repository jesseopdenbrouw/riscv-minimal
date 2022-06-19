CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: bootloader

bootloader: bootloader.c usart.c bl_startup.c util.c
	# Optimize for size
	$(CC) -Os -g -o bootloader bootloader.c usart.c util.c bl_startup.c -Wall -T bl_riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs
	$(OBJCOPY) -O srec bootloader bootloader.srec
	$(SREC2VHDL) -vw0 -i 8 bootloader.srec bootloader.vhd
clean:
	rm -f bootloader bootloader.srec bootloader.vhd
