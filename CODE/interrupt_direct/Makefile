CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
SREC2VHDL = ../bin/srec2vhdl

CFLAGS = -O2 -g -march=rv32im -mabi=ilp32
LDFLAGS = -Wall -T ../ldfiles/riscv.ld -march=rv32im -mabi=ilp32 -nostartfiles --specs=nano.specs

TARGET = main

OBJ = $(TARGET).o startup.o usart.o universal_handler.o handlers.o

all: $(TARGET)

%o: %c
	$(CC) -c $< -o $@


$(TARGET): $(TARGET).o startup.o universal_handler.o handlers.o usart.o
	$(CC) -O2 -g -o $(TARGET) $(OBJ) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET) $(TARGET).srec
	$(SREC2VHDL) -wf0 $(TARGET).srec $(TARGET).vhd

clean:
	rm -f $(TARGET) $(TARGET).srec $(TARGET).vhd $(OBJ)
