--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- ram_inst.vhd - The RAM

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The word size data is presented in Big Endian order,
-- but is written as four Little Endian 8-bit quantities.
-- The halfword size data is presented in Big Endian order,
-- but is written as two Little Endian 8-bit quantities,
-- There is no order for bytes (a.k.a. 8-bit quantities).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity ram_inst is
	port
	(
		address: in std_logic_vector (15 downto 0);
		byteena: in std_logic_vector (3 downto 0) :=  (others => '1');
		clock  : in std_logic  := '1';
		data   : in std_logic_vector (31 downto 0);
		wren   : in std_logic ;
		q      : out std_logic_vector (31 downto 0)
	);
END ram_inst;


architecture rtl of ram_inst is
signal ramll, ramlh, ramhl, ramhh : ram_type;
signal address_int : integer;
-- synthesis translate_off
-- Only for simulation, skip in synthesis
type ram_alt_type is array (0 to ram_size-1) of data_type;
signal ram_int : ram_alt_type;
-- synthesis translate_on
begin

    address_int <= to_integer(unsigned(address));
    
    -- For simulation only, now it can be used in the simulator.
-- synthesis translate_off
    process (ramll, ramlh, ramhl, ramhh) is
    begin
        for i in 0 to ram_size-1 loop
            ram_int(i) <= ramll(i) & ramlh(i) & ramhl(i) & ramhh(i);
        end loop;
    end process;
-- synthesis translate_on

    -- Four 8Kx8-bit RAM blocks (by default).
    -- Quartus will detect this and create onboard RAM
    ram0: process (clock) is
    begin
        if rising_edge(clock) then
            if byteena(0) = '1' then
                if wren = '1' then
                    ramll(address_int) <= data(7 downto 0);
                end if;
            end if;
            q(7 downto 0) <= ramll(address_int);
        end if;
    end process;

    ram1: process (clock) is
    begin
        if rising_edge(clock) then
            if byteena(1) = '1' then
                if wren = '1' then
                    ramlh(address_int) <= data(15 downto 8);
                end if;
            end if;
            q(15 downto 8) <= ramlh(address_int);
        end if;
    end process;

    ram2: process (clock) is
    begin
        if rising_edge(clock) then
            if byteena(2) = '1' then
                if wren = '1' then
                    ramhl(address_int) <= data(23 downto 16);
                end if;
              q(23 downto 16) <= ramhl(address_int);
            end if;
        end if;
    end process;
    
    ram3: process (clock) is
    begin
        if rising_edge(clock) then
            if byteena(3) = '1' then
                if wren = '1' then
                    ramhh(address_int) <= data(31 downto 24);
                end if;
            end if;
            q(31 downto 24) <= ramhh(address_int);
        end if;
    end process;

end architecture rtl;
