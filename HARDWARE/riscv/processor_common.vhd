--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- processor_common.vhd - Common types and constants

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_common is

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
    type pc_op_type is (pc_hold, pc_incr, pc_loadoffset, pc_loadoffsetregister, pc_branch);
    
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
                         alu_jal, alu_jalr,
                         alu_beq, alu_bne, alu_blt, alu_bge, alu_bltu, alu_bgeu
                        );
    -- The RAM
    -- NOTE: the RAM is 4x byte (8 bits) size, supporting
    --       32-bit Big Endian storage,
    --       so we have to recode to support Little Endian.
    --       Set ram_size_bits as if it were bytes
    -- NOTE: ram_size_bits must be <= 16
    constant ram_size_bits : integer := 14;
    constant ram_size : integer := 2**(ram_size_bits-2);
    -- The type of the RAM block, there are 4 blocks instantiated
    type ram_type is array (0 to ram_size-1) of std_logic_vector(7 downto 0);
                        
    -- The ROM
    -- NOTE: the ROM is word (32 bits) size.
    -- NOTE: data is in Little Endian format (as by the toolchain)
    --       for halfword and word entities
    --       Set rom_size_bits as if it were bytes
    -- NOTE: rom_size_bits must be <= 16
    constant rom_size_bits : integer := 14;
    constant rom_size : integer := 2**(rom_size_bits-2);
    type rom_type is array(0 to rom_size-1) of std_logic_vector(31 downto 0);
    -- The contents of the ROM is loaded by processor_common_rom.vhd
    
    -- The I/O
    -- NOTE: the I/O is word (32 bits) size, Big Endian
    --       there is no need to recode the data
    --       The I/O can only handle word size access
    --       Set io_size_bits as if it were bytes
    constant io_size_bits : integer := 3;
    constant io_size : integer := 2**(io_size_bits-2);
    type io_type is array (0 to io_size-1) of data_type;
    
    -- The highest nibble (4 bits) of the ROM, RAM and I/O
    -- This will set the memories at 256 MB intervals
    constant rom_high_nibble : std_logic_vector(3 downto 0) := x"0";
    constant ram_high_nibble : std_logic_vector(3 downto 0) := x"2";
    constant io_high_nibble : std_logic_vector(3 downto 0) := x"F";

end package processor_common;
