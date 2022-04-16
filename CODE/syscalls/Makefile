CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
AR = riscv32-unknown-elf-ar

TARGET = test

CFLAGS = -Wall -O2 -g -march=rv32im -mabi=ilp32 -Isyscalls
LDFLAGS = startup.o $(TARGET).o -static -g -lm -Lsyscalls -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=syscalls/libsys.specs --specs=syscalls/nano.specs


all: lib $(TARGET)

lib:
	make -C syscalls

$(TARGET): $(TARGET).c $(LIBSYS)
	$(CC) $(CFLAGS) -c crt/startup.c
	$(CC) $(CFLAGS) -c $(TARGET).c
	$(CC) -o $(TARGET) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET) $(TARGET).srec
	$(SREC2VHDL) -wf0 $(TARGET).srec $(TARGET).vhd

clean:
	make -C syscalls clean
	rm -f $(TARGET) $(TARGET).srec $(TARGET).vhd *.o
