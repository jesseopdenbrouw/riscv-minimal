CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

all: clock

clock: clock.c sysgettimeofday.c syssbrk.c
	$(CC) -std=c11 -O0 -g -o clock clock.c sysgettimeofday.c syssbrk.c -Wall -T ../ldfiles/riscv.ld -march=rv32im -nostartfiles --specs=nano.specs ../crt/startup.c
	$(OBJCOPY) -O srec clock clock.srec
	$(SREC2VHDL) -wf clock.srec clock.vhd
clean:
	rm -f clock clock.srec clock.vhd
