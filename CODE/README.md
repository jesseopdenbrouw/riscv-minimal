# Software programs for the RISC-V processor

This directory contains some sample software programs
to be run on the RISC-V 32-bit processor as can be
found in the hardware directory.

Examples include some basic function testing, usable
in simulation and more sophisticated examples (such
as interrupt handling) that run on the DE0-CV board.

We make extensive use of the volatile keyword to emit
variables to the RAM instead of keeping them in
registers, for easy inspection.

Programs are translated by the RISC-V GNU C/C++ compiler.
