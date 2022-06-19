--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- rom.vhd - Description of the ROM decoding unit

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the description of the ROM. The ROM
-- is placed in mutable onboard RAM blocks and can be changed
-- by writing to it. A read takes two clock cycles, for both
-- instruction and data. The ROM contents is placed in file
-- processor_common_rom.vhd.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity rom is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_address : in data_type;
          I_csrom : in std_logic;
          I_wren : in std_logic;
          I_size : in size_type;
          I_stall : in std_logic;
          O_instr : out data_type;
          I_datain : in data_type;
          O_data_out : out data_type;
          --
          O_instruction_misaligned_error : out std_logic;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end entity rom;

architecture rtl of rom is

-- The ROM itself
signal rom : rom_type := rom_contents;

begin

    O_instruction_misaligned_error <= '0' when I_pc(1 downto 0) = "00" else '1';        

    -- ROM, for both instructions and read-write data
    process (I_clk, I_areset, I_pc, I_address, I_csrom, I_size, I_wren, I_datain) is
    variable address_instr : integer range 0 to rom_size-1;
    variable address_data : integer range 0 to rom_size-1;
    variable instr_var : data_type;
    variable instr_recode : data_type;
    variable romdata_var : data_type;
    constant x : std_logic_vector(7 downto 0) := (others => 'X');
    begin
        -- Calculate addresses
        address_instr := to_integer(unsigned(I_pc(rom_size_bits-1 downto 2)));
        address_data := to_integer(unsigned(I_address(rom_size_bits-1 downto 2)));
 
        -- Reset store misaligned
        O_store_misaligned_error <= '0';
        
        -- Quartus will detect ROM table and uses onboard RAM
        if rising_edge(I_clk) then
            -- Read the instruction
            if I_stall = '0' then
                instr_var := rom(address_instr);
            end if;
            -- Read the data
            romdata_var := rom(address_data);
            -- Write the ROM
            if I_wren = '1' then
                rom(address_data) <= I_datain(7 downto 0) & I_datain(15 downto 8) & I_datain(23 downto 16) & I_datain(31 downto 24);
            end if;
        end if;

        -- Recode instruction
        O_instr <= instr_var(7 downto 0) & instr_var(15 downto 8) & instr_var(23 downto 16) & instr_var(31 downto 24);
        
        O_load_misaligned_error <= '0';
        
        -- By natural size, for data
        if I_csrom = '1' then
            if I_size = size_word and I_address(1 downto 0) = "00" then
                O_data_out <= romdata_var(7 downto 0) & romdata_var(15 downto 8) & romdata_var(23 downto 16) & romdata_var(31 downto 24);
            elsif I_size = size_halfword and I_address(1 downto 0) = "00" then
                O_data_out <= x & x & romdata_var(23 downto 16) & romdata_var(31 downto 24);
            elsif I_size = size_halfword and I_address(1 downto 0) = "10" then
                O_data_out <= x & x & romdata_var(7 downto 0) & romdata_var(15 downto 8);
            elsif I_size = size_byte then
                case I_address(1 downto 0) is
                    when "00" => O_data_out <= x & x & x & romdata_var(31 downto 24);
                    when "01" => O_data_out <= x & x & x & romdata_var(23 downto 16);
                    when "10" => O_data_out <= x & x & x & romdata_var(15 downto 8);
                    when "11" => O_data_out <= x & x & x & romdata_var(7 downto 0);
                    when others => O_data_out <= x & x & x & x; O_load_misaligned_error <= '1';
                end case;
            else
                -- Chip select, but not aligned
                O_data_out <= x & x & x & x;
                O_load_misaligned_error <= '1';
            end if;
        else
            -- No chip select, so no data
            O_data_out <= x & x & x & x;
        end if;
    end process;

end architecture rtl;
