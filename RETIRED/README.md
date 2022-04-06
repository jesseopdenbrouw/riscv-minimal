# retired

In this directory retired hardware version of the processor can be found.

They will not be used anymore.

# riscv

This implementation is very basic. Only the unpriviledged ISA is supported.
It does not have a multiply/divide unit and does not have a CSR and does not support traps.
Executing an instruction requires 2 clock cycles.

# riscv-pipe-csr
This implementation has a very basic CSR (but no trap handling) and no multiply/divide unit.
Instruction executing requires one clock cycle

# riscv-pipe-csr-md
This implementation has a very basic CSR (but no trap handling) and a multiply/divide unit.
Instruction executing requires one clock cycle

