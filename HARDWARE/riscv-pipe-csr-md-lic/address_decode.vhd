--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- address_decode.vhd - The address decoder and data router

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This is de address decoder and data router.The address is
-- examined and checked to ROM, RAM and I/O regions. If a
-- region is selected, the data from a region (read) is
-- selected and put on the data output (to the ALU). If
-- an illegal region is selected a address error is issued.
-- More regions may be added (e.g. ROM for a bootloader)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity address_decoder_and_data_router is
    port (I_rs : in data_type;
          I_offset : in data_type;
          I_romdatain : in data_type;
          I_ramdatain : in data_type;
          I_iodatain : in data_type;
          I_memaccess : in memaccess_type;
          O_dataout : out data_type;
          O_wrram : out std_logic;
          O_wrio : out std_logic;
          O_addressout : out data_type;
          O_waitfordata : out std_logic;
          O_csrom : out std_logic;
          O_csram : out std_logic;
          O_csio : out std_logic;
          O_load_access_error : out std_logic;
          O_store_access_error : out std_logic
   );
end entity address_decoder_and_data_router;

architecture rtl of address_decoder_and_data_router is
signal address : data_type;
begin

    -- Address decoding and data routing for ROM, RAM and I/O to registers
    address <= std_logic_vector(unsigned(I_rs) + unsigned(I_offset));
    O_addressout <= address;

    process (address, I_romdatain, I_ramdatain, I_iodatain, I_memaccess) is
    begin
        O_wrram <= '0';
        O_wrio <= '0';
        O_waitfordata <= '0';
        O_load_access_error <= '0';
        O_store_access_error <= '0';
        O_csrom <= '0';
        O_csram <= '0';
        O_csio <= '0';
        -- ROM @ 0xxxxxxx, 256M space, read only
        if address(31 downto 28) = rom_high_nibble then
            if I_memaccess = memaccess_read then
                O_csrom <= '1';
            end if;
            if I_memaccess = memaccess_read then
                O_waitfordata <= '1';
            end if;
            O_dataout <= I_romdatain;
        -- RAM @ 2xxxxxxx, 256M space
        elsif address(31 downto 28) = ram_high_nibble then
            if I_memaccess = memaccess_read or I_memaccess = memaccess_write then
                O_csram <= '1';
            end if;
            if I_memaccess = memaccess_write then
                O_wrram <='1';
            elsif I_memaccess = memaccess_read then
                O_waitfordata <= '1';
            end if;
            O_dataout <= I_ramdatain;
        -- I/O @ Fxxxxxxx, 256M space
        elsif address(31 downto 28) = io_high_nibble then
            if I_memaccess = memaccess_read or I_memaccess = memaccess_write then
                O_csio <= '1';
            end if;
            if I_memaccess = memaccess_write then
                O_wrio <='1';
            end if;
            O_dataout <= I_iodatain;
        else
            -- Check for read/write in unspecified address region
            if I_memaccess = memaccess_write then
                O_store_access_error <= '1';
            elsif I_memaccess = memaccess_read then
                O_load_access_error <= '1';
            end if;
            O_dataout <= (others => '-');
        end if;
    end process;

end architecture rtl;