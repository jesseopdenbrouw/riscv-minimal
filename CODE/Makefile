RISCVCC = riscv32-unknown-elf-gcc

all: 
	if [ ! -d bin ]; then mkdir bin; fi
	$(MAKE) -C srec2vhdl all
	cp srec2vhdl/srec2vhdl bin
	$(MAKE) -C srec2mif all
	cp srec2mif/srec2mif bin
	$(MAKE) -C add64 all
	$(MAKE) -C mult all
	$(MAKE) -C assembler all
	$(MAKE) -C testio all
	$(MAKE) -C flash all
	$(MAKE) -C shift all
	$(MAKE) -C string all
	$(MAKE) -C syscalls all
	$(MAKE) -C float all
	$(MAKE) -C double all
	$(MAKE) -C malloc all
	$(MAKE) -C trig all
	$(MAKE) -C ioadd all
	$(MAKE) -C global all
	$(MAKE) -C sprintf all
	$(MAKE) -C usart all
	$(MAKE) -C qsort_int all
	$(MAKE) -C riemann_left all

clean:
	$(MAKE) -C srec2vhdl clean
	$(MAKE) -C srec2mif clean
	$(MAKE) -C add64 clean
	$(MAKE) -C mult clean
	$(MAKE) -C assembler clean
	$(MAKE) -C testio clean
	$(MAKE) -C flash clean
	$(MAKE) -C shift clean
	$(MAKE) -C string clean
	$(MAKE) -C syscalls clean
	$(MAKE) -C float clean
	$(MAKE) -C double clean
	$(MAKE) -C malloc clean
	$(MAKE) -C trig clean
	$(MAKE) -C ioadd clean
	$(MAKE) -C global clean
	$(MAKE) -C sprintf clean
	$(MAKE) -C usart clean
	$(MAKE) -C qsort_int clean
	$(MAKE) -C riemann_left clean
	rm -rf bin
