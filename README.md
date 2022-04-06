# riscv-minimal

A (not so) minimalistic RISC-V 32-bit processor written in VHDL targeted
for an FPGA.

## Description

The RISV-C processor uses the RV32IM instruction set with the
exception of the FENCE and WFI instructions. Exceptions and interrupts are
supported. ECALL, EBREAK and MRET are supported. Currently only machine
mode is supported. We successfully tested a complex program with interrupts
and exceptions and implemented a basic syscall library usable with
the ECALL instruction as provided by the GNU C compiler for RISC-V.
sbrk, read, write and gettimeofday are basically
supported. The External (system) Timer is implemented and
generates an exception if time >= timecmp. External Interrupt are not
supported as the processor does not have a PLIC. Up to 16 fast local
interrupts are supported. The processor uses
a simple 2-stage instruction pipeline. Read from ROM and RAM require
2 clock cycles. Writes require 1 clock cycles. Multiplications require
3 clock cycles, divisions require 16+2 clock cycles. Jumps/calls/branches
taken require 2 clock cycles. Interrupts are direct or vectored.

Software is written in C (C++ currently not supported) and compiled
using the RISC-V GNU C compiler.
 
## Memory

The processor uses FPGA onboard RAM blocks to emulate RAM and program ROM.
Programs are compiled with the GNU C compiler for RISC-V and the resulting
executable is transformed to a VHDL synthesizable ROM table.

ROM: a ROM of 64 kB is available (placed in onboard RAM, may be extended).
RAM: a RAM of 32 kB using onboard RAM block available (may be extended).
I/O: a simple 32-bit input and 32-bit output is available, as
is a simple 7/8/9-bit UART with interrupt capabilities. A simple timer
with interrupt is provided. The External (system) Timer is located in
the I/O so it's memory mapped.

ROM starts at 0x00000000, RAM starts at 0x20000000, I/O starts
at 0xF0000000. May be changed on 256 MB (top 4 bits) sections.

## CSR

A number CSR registers are implemented: time, timeh, cycle, cycleh,
instret, instreth, mvendorid, marchid, mimpid, mhartid, mstatus,
mstatush, misa, mie, mtvec, mscratch, mepc, mcause, mip. Some of
these CSRs are hardwired. Others will be implemented when needed.
The time and timeh CSRs produces the time since reset in microseconds,
shadowed from the External Timer memory mapped registers.

## Software

Software support is still limited as can be expected with microcontrollers.
A number of C programs have been tested, created by the GNU C Compiler for
RISC-V. We tested the use of (software) floating point operations (both
float and double) and tested the mathematical library (sin, cos, et al.).
Assembler programs can be compiled by the C compiler. We provide a CRT
(C startup) and linker file.

## FPGA

The processor is developed on a Cyclone V FPGA with the use
of the DE0-CV board by Terasic and Quartus Prime Lite 21.1.
Simulation is possible with QuestaSim Intel Starter Edition.
You need a (free) license for that. The processor uses about
2700 ALM (cells) of 18480. Speed is currently 50 MHz max.

## Plans (or not)

We are *not* planning the C standard.
Plans to create a hardcoded bootloader to load programs when the processor is loaded in an FPGA.
We strive to implement SPI and I2C, and PWM.
We are considering implementing a 5-stage instruction pipeline (this will take time ;-)).
Implement Supervisor Mode (this will also take some time ;-).
Smaller (in cells) divide unit.

## Disclaimer

This processor is for educational purposes only.
Work in progress. Things might change. Use with care.

