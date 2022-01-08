# Hardware

## riscv

This directory contains the VHDL description of the processor.
The standard processor requires two clock cycles to execute
an instruction, has no CSR and no multiply/divide unit. The
pipelined processor also requires two clock cycle to execute
an instruction but the next instruction is fetched while
executing the current instruction. Then, jumps/branches taken
require an extra clock cycle. In both processors, a read from
RAM or ROM requires an extra clock cycle. The pipelined
processor has a very basic CSR set and has a hardware
multiply/divide unit.

## Status

Works on the DE0-CV board.
