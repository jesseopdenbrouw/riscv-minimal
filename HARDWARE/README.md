# Hardware

This directory contains the hardware description of the
RISC-V 32-bit processor.


## riscv-pipe-md-lic

The processor requires two clock cycle to execute
an instruction but the next instruction is fetched while
executing the current instruction. Then, jumps/branches taken
require an extra clock cycle. The processor has a basic CSR
set for trap handling and has a hardware multiply/divide unit.
Multiplications take three clock cycles, divisions take 18
or 34 clock cycles (depends on the implementation).

A number of software programs have been tested using the
GNU C compiler for RISC-V 32 bit. C++ is not supported.

## Status

Works on the DE0-CV board.
