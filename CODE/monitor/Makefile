CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: monitor

monitor: monitor.c io.h
	$(CC) -Os -g -o monitor monitor.c syssbrk.c -Wall -T ../ldfiles/riscv.ld -march=rv32i -mabi=ilp32 -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec monitor monitor.srec
	$(SREC2VHDL) -wf monitor.srec monitor.vhd
clean:
	rm -f monitor monitor.srec monitor.vhd
	rm -rf __pycache__
