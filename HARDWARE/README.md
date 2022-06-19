# Hardware

This directory contains the hardware description of the
RISC-V 32-bit processor.


## riscv-pipe-md-lic

The processor requires two clock cycles to execute
an instruction but the next instruction is fetched while
executing the current instruction. Then, jumps/branches taken
require an extra clock cycle. The processor has a basic CSR
set for trap handling and has a hardware multiply/divide unit.

A number of software programs have been tested using the
GNU C compiler for RISC-V 32 bit. C++ is supported but may
create a binary that is too big to fit in ROM.

## riscv-pipe3-csr-md-lic

This processor uses a three-stage pipeline to execute
instructions. Jumps/branches taken require three clock
cycles. The processor has a hardware integer
multiplication/division unit, a basic CSR set, and a
local interrupt controller.
Multiplications take three clock cycles, divisions take
16+3 or 32+3 clock cycles. 

A number of software programs have been tested using the
GNU C compiler for RISC-V 32 bit. C++ is supported but may
create a binary that is too big to fit in ROM.

## riscv-pipe3-csr-md-lic.bootloader

This is an extended version of the three-stage pipelined
processor and incorporates a hardcoded bootloader. The
bootloader is located at address 0x10000000. The bootloader
is able to load an S-record file into the ROM at address
0x00000000.

When the processor starts, the bootloader waits for about
5 seconds for a keboard press (using the USART). If not
within this 5 seconds, the bootloader starts the main
program at address 0x00000000. If pressed, the bootloader
enters a simple monitor program. Type 'h' for help.

A S-record file can be uploaded by the `upload` program.
If `upload` contacts the bootloader within the 5 second
delay, the S-record file is transmitted to the processorr
and the instructions are placed in the ROM (or RAM). Make
sure that NO terminal connection (e.g. Putty) is active.

## Status

Works on the DE0-CV board.
