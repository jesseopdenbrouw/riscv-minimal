--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- address_decode.vhd - The address decoder and data router

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

entity address_decoder_and_data_router is
    port (rs : in data_type;
          offset : in data_type;
          romdatain : in data_type;
          ramdatain : in data_type;
          iodatain : in data_type;
          memaccess : memaccess_type;
          dataout : out data_type;
          wrram : out std_logic;
          wrio : out std_logic;
          addressout : out data_type;
          waitfordata : out std_logic;
          addresserror : out std_logic
   );
end entity address_decoder_and_data_router;

architecture rtl of address_decoder_and_data_router is
signal address : data_type;
begin

    -- Address decoding and data routing for ROM, RAM and I/O to registers

    process (address, rs, offset, romdatain, ramdatain, iodatain, memaccess) is
    begin
        address <= std_logic_vector(unsigned(rs) + unsigned(offset));
        wrram <= '0';
        wrio <= '0';
        waitfordata <= '0';
        addresserror <= '0';
        -- ROM @ 0xxxxxxx, 256M space, read only
        if address(31 downto 28) = rom_high_nibble then
            dataout <= romdatain;
        -- I/O @ Fxxxxxxx, 256M space
        elsif address(31 downto 28) = io_high_nibble then
            if memaccess = memaccess_write then
                wrio <='1';
            end if;
            dataout <= iodatain;
        -- RAM @ 2xxxxxxx, 256M space
        elsif address(31 downto 28) = ram_high_nibble then
            if memaccess = memaccess_write then
                wrram <='1';
            elsif memaccess = memaccess_read then
                waitfordata <= '1';
            end if;
            dataout <= ramdatain;
        else
            dataout <= (others => '-');
            -- Check for read/write in unspecified address region
            if memaccess = memaccess_write or memaccess = memaccess_read then
                addresserror <= '1';
            end if;
        end if;
        addressout <= address;
    end process;

end architecture rtl;