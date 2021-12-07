# riscv-minimal
A minimalistic RISC-V 32-bit processor written in VHDL targeted for an FPGA

NOTE: This project is in its initial stage. Only a very limited
      set of program currently run on the processor.

The RISV-C processor uses the RV32I instruction set with the
exception of the FENCE, ECALL and EBREAK instructions.
Exceptions are currently not supported.
Software support is limited. Only very simple C programs
can run on the processor, created by the GNU C Compiler for
RISC-V. Assembler programs can be compiled by the C compiler.

The processor is developed on a Cyclone V FPGA with the use
of the DE0-CV board by Terasic and Quartus Prime Lite 21.1.
Simulation is possible with QuestaSim Intel Starter Edition.
You need a (free) license for that.

ROM: a ROM of 64 kB is available (may be extended).
RAM: a RAM of 32 kB using onboard RAM block available (may be extended).
I/O: a simple 32-bit input and 32-bit output is available, as
is a simple 8-bit UART.

ROM starts at 0x00000000, RAM starts at 0x20000000, I/O starts
at 0xF0000000.

We tested some simple C programs. It seems that integer, float
and double calculations work correctly, as is the sbrk system
call for use with malloc(). sprint is tested (also for floating
point) and seems to work. I/O functions (printf, scanf et al)
are not tested.

Work in progress. Things might change. Use with care.

