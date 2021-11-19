RISCVCC = riscv32-unknown-elf-gcc

all: 
	if [ ! -d bin ]; then mkdir bin; fi
	$(MAKE) -C srec2vhdl all
	cp srec2vhdl/srec2vhdl bin
	$(MAKE) -C add64 all
	$(MAKE) -C ctest all
	$(MAKE) -C mult all
	$(MAKE) -C assembler all
	$(MAKE) -C testio all
	$(MAKE) -C flash all
	$(MAKE) -C flash.alt all
	$(MAKE) -C shift all
	$(MAKE) -C string all

clean:
	$(MAKE) -C srec2vhdl clean
	$(MAKE) -C add64 clean
	$(MAKE) -C ctest clean
	$(MAKE) -C mult clean
	$(MAKE) -C assembler clean
	$(MAKE) -C testio clean
	$(MAKE) -C flash clean
	$(MAKE) -C flash.alt clean
	$(MAKE) -C shift clean
	$(MAKE) -C string clean
	rm -rf bin
