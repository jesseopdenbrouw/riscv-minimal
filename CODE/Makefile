RISCVCC = riscv32-unknown-elf-gcc

all: 
	if [ ! -d bin ]; then mkdir bin; fi
	$(MAKE) -C srec2vhdl all
	cp srec2vhdl/srec2vhdl bin
	$(MAKE) -C srec2mif all
	cp srec2mif/srec2mif bin
	$(MAKE) -C upload all
	cp upload/upload bin
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
	$(MAKE) -C monitor all
	$(MAKE) -C usart_printf all
	$(MAKE) -C usart_sprintf all
	$(MAKE) -C clock all
	$(MAKE) -C interval all
	$(MAKE) -C hex_display all
	$(MAKE) -C basel_problem all
	$(MAKE) -C interrupt_direct all
	$(MAKE) -C interrupt_vectored all
	$(MAKE) -C exp all
	$(MAKE) -C usart_cpp all
	$(MAKE) -C linked_list all
	$(MAKE) -C bootloader all

clean:
	$(MAKE) -C srec2vhdl clean
	$(MAKE) -C srec2mif clean
	$(MAKE) -C upload clean
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
	$(MAKE) -C monitor clean
	$(MAKE) -C usart_printf clean
	$(MAKE) -C usart_sprintf clean
	$(MAKE) -C clock clean
	$(MAKE) -C interval clean
	$(MAKE) -C hex_display clean
	$(MAKE) -C basel_problem clean
	$(MAKE) -C interrupt_direct clean
	$(MAKE) -C interrupt_vectored clean
	$(MAKE) -C exp clean
	$(MAKE) -C usart_cpp clean
	$(MAKE) -C linked_list clean
	$(MAKE) -C bootloader clean
	rm -rf bin
