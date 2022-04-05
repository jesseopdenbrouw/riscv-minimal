--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- ram.vhd - RAM interface between the core and the RAM block

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

library work;
use work.processor_common.all;

entity ram is
    port (I_clk : in std_logic;
          I_csram : in std_logic;
          I_address : in data_type;
          I_datain : in data_type;
          I_size : in size_type;
          I_wren : in std_logic;
          O_dataout : out data_type;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end entity ram;
 
architecture rtl of ram is

-- This component is instantiated
component ram_inst is
	port
	(
		address		: in std_logic_vector (15 downto 0);
		byteena		: in std_logic_vector (3 downto 0) :=  (others => '1');
		clock		: in std_logic := '1';
		data		: in std_logic_vector (31 downto 0);
		wren		: in std_logic;
		q		    : out std_logic_vector (31 downto 0)
	);
end component ram_inst;

signal address_int : std_logic_vector(15 downto 0);
signal datain_int : std_logic_vector(31 downto 0);
signal byteena_int : std_logic_vector(3 downto 0);
signal dataout_int : std_logic_vector(31 downto 0);
signal wren_int : std_logic;
begin
 
    -- Instantiate the RAM
    -- The RAM is 32 bits, Big Endian.
    ram_inst0: ram_inst
    port map(clock => I_clk,
             address => address_int,
             byteena => byteena_int,
             data => datain_int,
             wren => wren_int,
             q => dataout_int);
     
    -- Input & output recoding
    -- The RAM is 32 bits, Big Endian, so we have to recode the inputs
    -- to support Little Endian
    process (I_address, I_size, I_datain, I_wren, dataout_int, I_csram) is
    constant x : std_logic_vector(7 downto 0) := (others => '-');
    begin
        -- Need only the upper bits for address, the lower two bits select word, halfword or byte
        address_int <= (others => '0');
        address_int(ram_size_bits-3 downto 0) <= I_address(ram_size_bits-1 downto 2);
        
        -- Clear error, load write enable en set byte enable off
        O_load_misaligned_error <= '0';
        O_store_misaligned_error <= '0';
        wren_int <= I_wren;
        byteena_int <= "0000";
         
        -- Input recoding
        if I_csram = '1' then
            case I_size is
                -- Byte size
                when size_byte =>
                    case I_address(1 downto 0) is
                        when "00" => datain_int <= I_datain(7 downto 0) & x & x & x; byteena_int <= "1000";
                        when "01" => datain_int <= x & I_datain(7 downto 0) & x & x; byteena_int <= "0100";
                        when "10" => datain_int <= x & x & I_datain(7 downto 0) & x; byteena_int <= "0010";
                        when "11" => datain_int <= x & x & x & I_datain(7 downto 0); byteena_int <= "0001";
                        when others => datain_int <= x & x & x & x;
                    end case;
                -- Half word size, on 2-byte boundaries
                when size_halfword =>
                    if I_address(1 downto 0) = "00" then
                        datain_int <= I_datain(7 downto 0) & I_datain(15 downto 8) & x & x;
                        byteena_int <= "1100";
                    elsif I_address(1 downto 0) = "10" then
                        datain_int <= x & x & I_datain(7 downto 0) & I_datain(15 downto 8);
                        byteena_int <= "0011";
                    else
                        datain_int <=  x & x & x & x;
                        O_store_misaligned_error <= '1';
                        wren_int <= '0';
                    end if;
                -- Word size, on 4-byte boundaries
                when size_word =>
                    if I_address(1 downto 0) = "00" then
                        datain_int <= I_datain(7 downto 0) & I_datain(15 downto 8) & I_datain(23 downto 16) & I_datain(31 downto 24);
                        byteena_int <= "1111";
                    else
                        datain_int <=  x & x & x & x;
                        O_store_misaligned_error <= '1';
                        wren_int <= '0';
                    end if;
                when others =>
                    datain_int <= x & x & x & x;
                    -- Do not write the RAM
                    wren_int <= '0';
                    O_store_misaligned_error <= '1';
            end case;
        else
            -- set write enable to 0 anyway
            wren_int <= '0';
            datain_int <= x & x & x & x;
        end if;
        

        -- Output recoding
        if I_csram = '1' then
            case I_size is
                -- Byte size
                when size_byte =>
                    case I_address(1 downto 0) is
                        when "00" => O_dataout <= x & x & x & dataout_int(31 downto 24);
                        when "01" => O_dataout <= x & x & x & dataout_int(23 downto 16);
                        when "10" => O_dataout <= x & x & x & dataout_int(15 downto 8);
                        when "11" => O_dataout <= x & x & x & dataout_int(7 downto 0);
                        when others => O_dataout <= x & x & x & x;
                    end case;
                -- Half word size
                when size_halfword =>
                    if I_address(1 downto 0) = "00" then
                        O_dataout <= x & x & dataout_int(23 downto 16) & dataout_int(31 downto 24);
                    elsif I_address(1 downto 0) = "10" then
                        O_dataout <= x & x & dataout_int(7 downto 0) & dataout_int(15 downto 8);
                    else
                        O_dataout <= x & x & x & x;
                        O_load_misaligned_error <= '1';
                    end if;
                -- Word size
                when size_word =>
                    if I_address(1 downto 0) = "00" then
                        O_dataout <= dataout_int(7 downto 0) & dataout_int(15 downto 8) & dataout_int(23 downto 16) & dataout_int(31 downto 24);
                    else
                        O_dataout <= x & x & x & x;
                        O_load_misaligned_error <= '1';
                    end if;
                when others =>
                    O_dataout <= x & x & x & x;
            end case;
        else
            O_dataout <= x & x & x & x;
        end if;
    end process;
 
 end architecture rtl;
 