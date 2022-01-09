--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- md.vhd - The Multiply and Divide Unit

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

entity md is
    port (clk : in std_logic;
          areset : in std_logic;
          start : in std_logic;
          op : in std_logic_vector(2 downto 0);
          rs1, rs2 : in data_type;
          ready : out std_logic;
          mul_rd : out data_type;
          div_rd : out data_type
         );
end entity md;

architecture rtl of md is

signal rdata_a, rdata_b : unsigned(32 downto 0);
signal rddata : unsigned(63 downto 0);
signal mul_rd_int : signed(65 downto 0);
signal mul_running : std_logic;
signal mul_ready : std_logic;

signal buf: unsigned(63 downto 0);
signal dbuf: unsigned(31 downto 0);
signal quotient : unsigned(31 downto 0);
signal remainder : unsigned(31 downto 0);
signal count: integer range 0 to 33;
signal outsign : std_logic;
signal div_ready : std_logic;

constant all_zeros : std_logic_vector(31 downto 0) := (others => '0');
 
alias buf1 is buf(63 downto 32); 
alias buf2 is buf(31 downto 0); 

begin

    process (clk, areset) is
    begin
        if areset = '1' then
            rdata_a <= (others => '0');
            rdata_b <= (others => '0');
            mul_running <= '0';
        elsif rising_edge(clk) then
            -- Clock in the multiplicand and multiplier
            -- In the Cyclone V, these are embedded registers
            -- in the DSP units.
            if op(1) = '1' then
                if op(0) = '1' then
                    rdata_a <= '0' & unsigned(rs1);
                else
                    rdata_a <= rs1(31) & unsigned(rs1);
                end if;
                rdata_b <= '0' & unsigned(rs2);
            else
                rdata_a <= rs1(31) & unsigned(rs1);
                rdata_b <= rs2(31) & unsigned(rs2);
            end if;
            -- Only start when start seen and multiply
            mul_running <= start and not op(2);
        end if;
    end process;

    process(clk, areset) is
    begin
        if areset = '1' then
            mul_rd_int <= (others => '0');
            mul_ready <= '0';
        elsif rising_edge (clk) then
            -- Do the multiplication and store in embedded registers
            mul_rd_int <= signed(rdata_a) * signed(rdata_b);
            mul_ready <= mul_running;
        end if;
    end process;
    
    process (mul_rd_int, op) is
    begin
        if op(1) = '1' or op(0) = '1' then
            mul_rd <= std_logic_vector(mul_rd_int(63 downto 32));
        else
            mul_rd <= std_logic_vector(mul_rd_int(31 downto 0));
        end if;
    end process;
    
    process (clk, areset)
    variable div_running : std_logic;  
    begin 
        if areset = '1' then
            -- Reset everything
            quotient <= (others => '0'); 
            remainder <= (others => '0'); 
            count <= 0;
            buf1 <= (others => '0');
            buf2 <= (others => '0');
            dbuf <= (others => '0');
            div_running := '0';
            div_ready <= '0';
            outsign <= '0';
        elsif rising_edge(clk) then 
            -- If start and dividing...
            div_ready <= '0';
            if start = '1' and op(2) = '1' then
                div_running := '1';
            end if;
            if div_running = '1' then
                case count is 
                when 0 => 
                    buf1 <= (others => '0');
                    -- If signed divide, check for negative
                    -- value and make it positive
                    if op(0) = '0' and rs1(31) = '1' then
                        buf2 <= unsigned(not rs1) + 1;
                    else
                        buf2 <= unsigned(rs1);
                    end if;
                    if op(0) = '0' and rs2(31) = '1' then
                        dbuf <= unsigned(not rs2) + 1;
                    else
                        dbuf <= unsigned(rs2); 
                    end if;
                    count <= count + 1; 
                    div_running := '1';
                    div_ready <= '0';
                    if (op(0) = '0' and op(1) = '0' and (rs1(31) /= rs2(31)) and rs2 /= all_zeros) or (op(0) = '0' and op(1) = '1' and rs1(31) = '1') then
                        outsign <= '1';
                    else
                        outsign <= '0';
                    end if;

                when others =>
                    -- Do the divide
                    if buf(62 downto 31) >= dbuf then 
                        buf1 <= '0' & (buf(61 downto 31) - dbuf(30 downto 0)); 
                        buf2 <= buf2(30 downto 0) & '1'; 
                    else 
                        buf <= buf(62 downto 0) & '0'; 
                    end if;
                    -- Do this 33 times (32 bit + 1 output)
                    if count /= 33 then 
                        count <= count + 1;
                    else
                        -- Ready, show the result
                        count <= 0;
                        if outsign = '1' then
                            quotient <= not buf2 + 1;
                            remainder <= not buf1 + 1;
                        else
                            quotient <= buf2;
                            remainder <= buf1; 
                        end if;
                        div_running := '0';
                        div_ready <= '1';
                    end if; 
                end case; 
            end if; 
        end if; 
    end process;
    
    div_rd <= std_logic_vector(remainder) when op(1) = '1' else std_logic_vector(quotient);
    
    ready <= div_ready or mul_ready;

end architecture rtl;
