--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- rom.vhd - Interface between the ROM data, instruction decoder
--           and ALU.

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
    port (
        clk : in std_logic;
        address1 : in data_type;
        address2 : in data_type;
        size2 : size_type;
        data1 : out data_type;
        data2: out data_type;
        error : out std_logic
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
    port map ( clock => clk,
               address_a => address1(rom_size_bits-1 downto 2),
               address_b => address2(rom_size_bits-1 downto 2),
               q_a => instr,
               q_b => data
    );
    

    -- ROM decoder
    process(address1, address2, instr, data, size2) is
    begin
        error <= '0';
        -- By 4 for instructions
        if address1(1 downto 0) = "00" then
            data1 <= instr(7 downto 0) & instr(15 downto 8) & instr(23 downto 16) & instr(31 downto 24);
            --data1 <= rom(address1_int+0) & rom(address1_int+1) & rom(address1_int+2) & rom(address1_int+3);
        else
            data1 <= x;
            error <= '1';
        end if;
     
        -- By natural size
        if size2 = size_word and address2(1 downto 0) = "00" then
            data2 <= data(7 downto 0) & data(15 downto 8) & data(23 downto 16) & data(31 downto 24);
        elsif size2 = size_halfword and address2(1 downto 0) = "00" then
            data2 <= x(31 downto 16) & data(23 downto 16) & data(31 downto 24);
        elsif size2 = size_halfword and address2(1 downto 0) = "10" then
            data2 <= x(31 downto 16) & data(7 downto 0) & data(15 downto 8);
        elsif size2 = size_byte then
            case address2(1 downto 0) is
                when "00" => data2 <= x(31 downto 8) & data(31 downto 24);
                when "01" => data2 <= x(31 downto 8) & data(23 downto 16);
                when "10" => data2 <= x(31 downto 8) & data(15 downto 8);
                when "11" => data2 <= x(31 downto 8) & data(7 downto 0);
                when others => data2 <= x; error <= '1';
            end case;
        else
            data2 <= x;
            error <= '1';
        end if;
    end process;
    
end architecture table;
