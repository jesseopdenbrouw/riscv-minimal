--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- io.vhd - Simple I/O register file

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity io is
    port (clk : in std_logic;
          areset : in std_logic;
          address : in data_type;
          size : size_type;
          wren : in std_logic;
          datain : in data_type;
          dataout : out data_type;
          -- connection with outside world
          datainfromoutside : in data_type;
          dataouttooutside : out data_type
         );
end entity io;

architecture rtl of io is
signal io : io_type;
signal address_int : integer range 0 to io_size-1;
begin

    -- Fetch internal address of io_size_bits bits minus 2
    -- because we will use word size only
    address_int <= to_integer(unsigned(address(io_size_bits+1 downto 2)));
    
    process (clk, areset) is
    begin
        if areset = '1' then
            io(0) <= (others => '0');
            io(1) <= (others => '0');
        elsif rising_edge(clk) then
            -- Read data in from outside world
            io(0) <= datainfromoutside;
            -- Only write to I/O when write is enabled AND size is word
            -- Only write to the outputs, not the inputs
            -- Only write if on 4-byte boundary
            if wren = '1' and size = size_word and address(1 downto 0) = "00" then
                if address_int = 1 then
                    io(1) <= datain;
                end if;
            end if;
        end if;
    end process;
 
    -- Data out to ALU
    process (io, size, address, address_int) is
    begin
        if size = size_word and address(1 downto 0) = "00" then
            dataout <= io(address_int);
        else
            dataout <= (others => 'X');
        end if;
    end process;
    
    dataouttooutside <= io(1);
    
end architecture rtl;
      
