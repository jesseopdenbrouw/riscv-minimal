# Hardware

## riscv

This directory contains the VHDL description of the processor.
The standard processor requires two clock cycles to execute
an instruction. The pipelined processor requires one clock
cycle to execute an instruction. Then, jumps/branches taken
require an extra clock cycle. In both processors, a read from
RAM or ROM requires an extra clock cycle.
