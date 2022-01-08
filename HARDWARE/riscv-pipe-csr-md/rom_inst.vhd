--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- rom_inst.vhd - VHDL description of the ROM table
--
-- This software is for educational purposes only. 
-- This software is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.
--

-- Load system libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Load work libraries
library work;
use work.processor_common.all;
use work.processor_common_rom.all;

-- The ROM itself. This is not what the processor sees.
-- Quartus will synthesize ROM from RAM block
entity rom_inst is
	port
	(
		address_a		: in std_logic_vector (rom_size_bits-3 downto 0);
		address_b		: in std_logic_vector (rom_size_bits-3 downto 0);
		clock		: in std_logic  := '1';
		q_a		: out data_type;
		q_b		: out data_type
	);
end entity rom_inst;

-- Just synthesize the ROM as an onboard RAM block
architecture syn of rom_inst is
signal rom : rom_type := rom_contents;

begin

    -- Quartus will synthesize ROM from RAM block
    process(clock, address_a, address_b) is
    variable adda_int : integer range 0 to rom_size-1;
    variable addb_int : integer range 0 to rom_size-1;
    begin
        adda_int := to_integer(unsigned(address_a));
        addb_int := to_integer(unsigned(address_b));
        
        if rising_edge(clock) then
            q_a <= rom(adda_int);
            q_b <= rom(addb_int);
        end if;
        
    end process;

END SYN;

