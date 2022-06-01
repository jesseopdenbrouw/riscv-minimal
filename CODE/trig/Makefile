CC = riscv32-unknown-elf-gcc
CXX = riscv32-unknown-elf-g++
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl
AR = riscv32-unknown-elf-ar

TARGET = trig
STARTUP = crt/startup

CFLAGS = -Wall -O2 -g -march=rv32im -mabi=ilp32 -Isyscalls
LDFLAGS = $(STARTUP).o $(TARGET).o -static -g -lm -Lsyscalls -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=syscalls/libsys.specs --specs=syscalls/nano.specs -u _printf_float


all: lib crt $(TARGET)

crt: $(TARGET).o
	make -C crt

lib: $(TARGET).o
	make -C syscalls

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -c $(TARGET).c
	$(CC) -o $(TARGET) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET) $(TARGET).srec
	$(SREC2VHDL) -wf0 $(TARGET).srec $(TARGET).vhd

clean:
	make -C syscalls clean
	make -C crt clean
	rm -f $(TARGET) $(TARGET).srec $(TARGET).vhd *.o
