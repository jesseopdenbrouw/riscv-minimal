--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- address_decode.vhd - Address decoding and data router

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the description of address decoder and
-- data router, it interconnects the core with memory (ROM, RAM
-- and I/O).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity address_decode is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- to core
          I_memaccess : in memaccess_type;
          I_address : in data_type;
          O_waitfordata : out std_logic;
          O_dataout : out data_type; 
          -- to memory
          O_wrrom : out std_logic;
          O_wrram : out std_logic;
          O_wrio : out std_logic;
          O_csrom : out std_logic;
          O_csboot : out std_logic;
          O_csram : out std_logic;
          O_csio : out std_logic;
          I_romdatain : in data_type;
          I_bootdatain : in data_type;
          I_ramdatain : in data_type;
          I_iodatain : in data_type;
          O_load_access_error : out std_logic;
          O_store_access_error : out std_logic
         );
end entity address_decode;

architecture rtl of address_decode is
begin

    -- Address decoder and data router (may be forward from RS1)
    process (I_memaccess, I_address, I_romdatain, I_bootdatain, I_ramdatain, I_iodatain) is
    variable address_var : unsigned(31 downto 0);
    begin
        
        O_wrrom <= '0';
        O_wrram <= '0';
        O_wrio <= '0';
        
        O_waitfordata <= '0';
        
        O_csrom <= '0';
        O_csboot <= '0';
        O_csram <= '0';
        O_csio <= '0';
        
        O_load_access_error <= '0';
        O_store_access_error <= '0';
        
        -- ROM @ 0xxxxxxx, 256M space, read-write
        if I_address(31 downto 28) = rom_high_nibble then
            if I_memaccess = memaccess_read or I_memaccess = memaccess_write then
                O_csrom <= '1';
            end if;
            if I_memaccess = memaccess_write then
                O_wrrom <= '1';
            elsif I_memaccess = memaccess_read then
                O_waitfordata <= '1';
            end if;
            O_dataout <= I_romdatain;
        -- Bootloader ROM @ 1xxxxxxx, 256M space, read only
        elsif I_address(31 downto 28) = bootloader_high_nibble then
            if I_memaccess = memaccess_read then
                O_csboot <= '1';
            end if;
            if I_memaccess = memaccess_read then
                O_waitfordata <= '1';
            end if;
            O_dataout <= I_bootdatain;
        -- RAM @ 2xxxxxxx, 256M space
        elsif I_address(31 downto 28) = ram_high_nibble then
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
        elsif I_address(31 downto 28) = io_high_nibble then
            if I_memaccess = memaccess_read or I_memaccess = memaccess_write then
                O_csio <= '1';
            end if;
            if I_memaccess = memaccess_write then
                O_wrio <='1';
            elsif I_memaccess = memaccess_read then
                O_waitfordata <= '1';
            end if;
            O_dataout <= I_iodatain;
        else
            O_dataout <= (others => 'X');
        end if;
    end process;

end architecture rtl;

