--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- instr_router.vhd - Instruction router

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The instruction router routes instructions from the main ROM
-- and the boot rom.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity instruction_router is
    port (I_pc : in data_type;
          I_instr_rom : in data_type;
          I_instr_boot : in data_type;
          O_instr_out : out data_type
         );
end entity instruction_router;

architecture rtl of instruction_router is
begin

    process (I_pc, I_instr_rom, I_instr_boot) is
    begin
        if I_pc(31 downto 28) = rom_high_nibble then
            O_instr_out <= I_instr_rom;
        elsif I_pc(31 downto 28) = bootloader_high_nibble then
            O_instr_out <= I_instr_boot;
        else
            O_instr_out <= (others => '0');
        end if;
    end process;
    
end architecture;