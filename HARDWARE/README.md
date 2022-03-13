# Hardware

This directory contains the hardware descriptions of the
RISC-V 32-bit processors.


## riscv

The standard processor requires two clock cycles to execute
an instruction, has no CSR and no multiply/divide unit. A
read from ROM and RAM (data) takes an extra clock cycle because
ROM and RAM are implemented using onboard RAM blocks.

## riscv-pipe-md

The pipelined processor also requires two clock cycle to execute
an instruction but the next instruction is fetched while
executing the current instruction. Then, jumps/branches taken
require an extra clock cycle. The pipelined processor has a
very basic CSR set and has a hardware multiply/divide unit.
Multiplications take three clock cycles, divisions take 18
or 34 clock cycles (depends on the implementation).

## Status

Works on the DE0-CV board.
