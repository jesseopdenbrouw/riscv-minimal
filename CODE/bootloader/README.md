# THUAS RISC-V sample bootloader

Sample bootloader for the THUAS RISC-V microcontroller
on a FPGA.

## What is this?

The bootloader is loaded at address 0x10000000 of the
address space and is executed at startup. It waits for
about 5 seconds (@ 50 MHz) before it jumps to the
application at address 0x00000000. If a character is
received via the USART within these 5 seconds, a
prompt is shown and the user can enter commands. The
command "r" (without the quotes) starts the main
application.

An S-record file can be uploaded using the `upload`
program. If the bootloader is contacted within the
5 second grace period, the S-record file is uploaded
to the ROM (or RAM, but programs can only be started
from ROM).

## Status

Works on the board.