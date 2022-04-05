--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- rom.vhd - Interface between the core and the ROM block.

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The ROM is word size only for instruction.
-- Constants may also be in halfword or byte sizes.
-- All ROM entries are in Little Endian order.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity rom is
    port (I_clk : in std_logic;
          I_csrom : in std_logic;
          I_address1 : in data_type;
          I_address2 : in data_type;
          I_size2 : in size_type;
          O_data1 : out data_type;
          O_data2: out data_type;
          O_load_misaligned_error : out std_logic
         );
end entity rom;
 
architecture table of rom is
component rom_inst is
	port
	(
		address_a		: in std_logic_vector (rom_size_bits-3 downto 0);
		address_b		: in std_logic_vector (rom_size_bits-3 downto 0);
		clock		: in std_logic  := '1';
		q_a		: out data_type;
		q_b		: out data_type
	);
end component rom_inst;

signal instr : data_type;
signal data : data_type;
constant x : data_type := (others => 'X');
begin

    rom_inst0 : rom_inst
    port map ( clock => I_clk,
               address_a => I_address1(rom_size_bits-1 downto 2),
               address_b => I_address2(rom_size_bits-1 downto 2),
               q_a => instr,
               q_b => data
    );
    

    -- ROM decoder
    process(I_address1, I_address2, instr, data, I_size2, I_csrom) is
    begin
        O_load_misaligned_error <= '0';
        
        -- By 4 for instructions
        if I_address1(1 downto 0) = "00" then
            O_data1 <= instr(7 downto 0) & instr(15 downto 8) & instr(23 downto 16) & instr(31 downto 24);
        else
            O_data1 <= x;
            -- Instruction misaligned error is handled by checking the value of the PC
            --load_misaligned_error <= '1';
        end if;
     
        -- By natural size, for data
        if I_csrom = '1' then
            if I_size2 = size_word and I_address2(1 downto 0) = "00" then
                O_data2 <= data(7 downto 0) & data(15 downto 8) & data(23 downto 16) & data(31 downto 24);
            elsif I_size2 = size_halfword and I_address2(1 downto 0) = "00" then
                O_data2 <= x(31 downto 16) & data(23 downto 16) & data(31 downto 24);
            elsif I_size2 = size_halfword and I_address2(1 downto 0) = "10" then
                O_data2 <= x(31 downto 16) & data(7 downto 0) & data(15 downto 8);
            elsif I_size2 = size_byte then
                case I_address2(1 downto 0) is
                    when "00" => O_data2 <= x(31 downto 8) & data(31 downto 24);
                    when "01" => O_data2 <= x(31 downto 8) & data(23 downto 16);
                    when "10" => O_data2 <= x(31 downto 8) & data(15 downto 8);
                    when "11" => O_data2 <= x(31 downto 8) & data(7 downto 0);
                    when others => O_data2 <= x; O_load_misaligned_error <= '1';
                end case;
            else
                -- Chip select, but not aligned
                O_data2 <= x;
                O_load_misaligned_error <= '1';
            end if;
        else
            -- No chip select, so no data
            O_data2 <= x;
        end if;
    end process;
    
end architecture table;
