CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: interval

interval: interval.c sysgettimeofday.c syssbrk.c
	$(CC) -std=c11 -O0 -g -o interval interval.c sysgettimeofday.c syssbrk.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec interval interval.srec
	$(SREC2VHDL) -wf interval.srec interval.vhd
clean:
	rm -f interval interval.srec interval.vhd
