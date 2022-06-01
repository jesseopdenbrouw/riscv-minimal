CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
AR = riscv32-unknown-elf-ar

TARGET = linked_list
CRT = crt/startup.o

CFLAGS = -Wall -O2 -g -march=rv32im -mabi=ilp32 -Isyscalls
LDFLAGS = $(CRT) $(TARGET).o -static -g -lm -Lsyscalls -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=syscalls/libsys.specs --specs=syscalls/nano.specs

all: lib crt $(TARGET)

lib:
	make -C syscalls

crt: crt/startup.o
	make -C crt

$(TARGET): lib crt $(TARGET).c
	$(CC) $(CFLAGS) -c $(TARGET).c
	$(CC) -o $(TARGET) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET) $(TARGET).srec
	$(SREC2VHDL) -wf0 $(TARGET).srec $(TARGET).vhd

clean:
	make -C syscalls clean
	make -C crt clean
	rm -f $(TARGET) $(TARGET).srec $(TARGET).vhd *.o


