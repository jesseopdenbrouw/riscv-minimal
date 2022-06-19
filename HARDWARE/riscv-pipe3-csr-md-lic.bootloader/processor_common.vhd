--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- processor_common.vhd - Common types and constants

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the common types and constants for the
-- processor. It also contains definitions for the system frequency
-- frequency, the real time clock frequency, the number of registers
-- (32 of 16) and the option to include or exclude the hardware
-- integer divide and multiply unit.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_common is

    -- Set to board frequency
    constant SYSTEM_FREQUENCY : integer := 50000000;
    -- Set to 1 MHz, so elapsed time is in micro seconds
    constant CLOCK_FREQUENCY : integer := 1000000;
    
    -- Make use of the E standard (reduced register set),
    -- set to 16. For the I standard, use 32.
    constant NUMBER_OF_REGISTERS : integer := 32;
    
    -- Do we have the integer multiply/divide unit?
    constant HAVE_MULDIV : boolean := TRUE;
    -- Fast divide (needs more area)?
    constant FAST_DIVIDE : boolean := TRUE;
    
    -- Do we enable vectored mode for mtvec?
    constant VECTORED_MTVEC : boolean := TRUE;

    -- mstatus.MIE disables only interrupts (true) or all traps (false)
    constant MSTATUS_MIE_DISABLES_INTERRUPTS : boolean := TRUE;
    
    -- Do we have a boot ROM?
    constant HAVE_BOOT_ROM : boolean := TRUE;
    
    -- The common data type is 32 bits wide
    subtype data_type is std_logic_vector(31 downto 0);
    
    -- For shifts with immediate operand
    subtype shift_type is std_logic_vector(4 downto 0);
    
    -- For selecting registers
    subtype reg_type is std_logic_vector(4 downto 0);
    
    -- Opcode is 7 bits in instruction
    subtype opcode_type is std_logic_vector(6 downto 0);
    
    -- Func3 extra function bits in instruction
    subtype func3_type is std_logic_vector(2 downto 0);

    -- Func7 extra function bits in instruction
    subtype func7_type is std_logic_vector(6 downto 0);
    
    -- Behavior of the Program Counter
    type pc_op_type is (pc_hold, pc_incr, pc_loadoffset, pc_loadoffsetregister, pc_branch, pc_load_mepc, pc_load_mtvec);
    
    -- Size of memory access
    type size_type is (size_unknown, size_byte, size_halfword, size_word);
    
    -- Memory access type
    type memaccess_type is (memaccess_nop, memaccess_write, memaccess_read);
    
    -- ALU operations
    type alu_op_type is (alu_nop, alu_add, alu_sub, alu_and, alu_or, alu_xor,
                         alu_slt, alu_sltu,
                         alu_addi, alu_andi, alu_ori, alu_xori,
                         alu_slti, alu_sltiu,
                         alu_sll, alu_srl, alu_sra,
                         alu_slli, alu_srli, alu_srai,
                         alu_lui, alu_auipc,
                         alu_lw, alu_lh, alu_lhu, alu_lb, alu_lbu,
                         alu_sw, alu_sh, alu_sb,
                         alu_jal, alu_jalr,
                         alu_beq, alu_bne, alu_blt, alu_bge, alu_bltu, alu_bgeu,
                         alu_csr,
                         alu_multiply,
                         alu_divrem,
                         alu_trap, alu_mret, alu_unknown
                        );
                        
    -- Control and State register operations
    type csr_op_type is (csr_nop, csr_rw, csr_rs, csr_rc, csr_rwi, csr_rsi, csr_rci);
    
    -- Interrupt types
    type interrupt_request_type is (irq_none, irq_hard, irq_soft);

    -- The ROM
    -- NOTE: the ROM is word (32 bits) size.
    -- NOTE: data is in Little Endian format (as by the toolchain)
    --       for half word and word entities
    --       Set rom_size_bits as if it were bytes
    --       default is 64 kB data
    constant rom_size_bits : integer := 16;
    constant rom_size : integer := 2**(rom_size_bits-2);
    type rom_type is array(0 to rom_size-1) of data_type;
    -- The contents of the ROM is loaded by processor_common_rom.vhd
    
    -- The bootloader ROM
    -- NOTE: the bootloader ROM is word (32 bits) size.
    -- NOTE: data is in Little Endian format (as by the toolchain)
    --       for half word and word entities
    --       Set bootloader rom_size_bits as if it were bytes
    --       default is 8 kB data
    constant bootloader_size_bits : integer := 13;
    constant bootloader_size : integer := 2**(bootloader_size_bits-2);
    type bootloader_type is array(0 to bootloader_size-1) of data_type;
    -- The contents of the bootloader ROM is loaded by bootloader.vhd
    
    -- The RAM
    -- NOTE: the RAM is 4x byte (8 bits) size, supporting
    --       32-bit Big Endian storage,
    --       so we have to recode to support Little Endian.
    --       Set ram_size_bits as if it were bytes
    -- Default is 32 kB data
    constant ram_size_bits : integer := 15;
    constant ram_size : integer := 2**(ram_size_bits-2);
    -- The type of the RAM block
    type ram_type is array (0 to ram_size-1) of std_logic_vector(7 downto 0);
                        
    -- The I/O
    -- NOTE: the I/O is word (32 bits) size, Big Endian
    --       there is no need to recode the data
    --       The I/O can only handle word size access
    --       Set io_size_bits as if it were bytes
    -- Default 128 bytes data
    constant io_size_bits : integer := 8;
    constant io_size : integer := 2**(io_size_bits-2);
    type io_type is array (0 to io_size-1) of data_type;
    
    -- The Control and Status Registers
    -- Keep csr_size_bits to 12!!!
    -- The CSR have their own address space, it is not
    -- visible on the 4 GB normal address space.
    constant csr_size_bits : integer := 12;
    constant csr_size : integer := 2**csr_size_bits;
    type csr_type is array (0 to csr_size-1) of data_type;
    subtype csraddr_type is std_logic_vector(csr_size_bits-1 downto 0);
    subtype csrimmrs1_type is std_logic_vector(4 downto 0);

    -- The highest nibble (4 bits) of the ROM, bootloader, RAM and I/O
    -- This will set the memories at 256 MB intervals
    constant rom_high_nibble : std_logic_vector(3 downto 0) := x"0";
    constant bootloader_high_nibble : std_logic_vector(3 downto 0) := x"1";
    constant ram_high_nibble : std_logic_vector(3 downto 0) := x"2";
    constant io_high_nibble : std_logic_vector(3 downto 0) := x"F";

end package processor_common;
