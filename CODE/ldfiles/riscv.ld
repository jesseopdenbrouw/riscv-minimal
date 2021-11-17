ENTRY( _start )

MEMORY
{
   ROM (rx)   : ORIGIN = 0x00000000, LENGTH = 16K
   RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 16K
   IO (rw)    : ORIGIN = 0xf0000000, LENGTH = 16K
}

PHDRS
{
  ROM PT_LOAD;
}

SECTIONS
{
  .text : { 

    _stext = .;
    *(.text.start_up_code)
    *(.text.start_up_code_c)
    *(.text)
    *(.text*) 
    *(.text.unlikely)
    *(.text.unlikely.*)
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    _etext = .;

   } >ROM :ROM


  .srodata :
  {
    _srodata = .;
    *(.rdata)
    *(.rdata.*)
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
    *(.gnu.linkonce.r.*)
    . = ALIGN(4);
    _erodata = .;
  } >ROM :ROM


  .preinit_array     :
  {
    /*. = ALIGN(4); */
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  .init_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  .fini_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  . = ALIGN(4);
  _start_of_rom_to_copy = .;
  PROVIDE(_start_of_rom_to_copy = .);

  /* . = ALIGN(4); */

  .sdata : {
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } >RAM AT>ROM

  /* Calculate the lenght of the initialized RAM */
  /*_ram_length = . - ORIGIN(RAM); */

  . = ALIGN(4);
  .bss :
  {
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    /* __bss_start__ = _sbss; */
    *(.sbss)
    *(.sbss*)
    *(.bss)
    *(.bss*)
    *(COMMON)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    /* __bss_end__ = _ebss; */
  } >RAM AT>RAM

  . = ALIGN(16);
  __global_pointer$ = . + 0x800;

__stack_pointer$ = ORIGIN(RAM) + LENGTH(RAM);

  /* End of uninitialized data segment (used by syscalls.c for heap) */
  PROVIDE( end = . );
  _end = ALIGN(8);

  _start_ram = ORIGIN(RAM);
  _start_io = ORIGIN(IO);
}

