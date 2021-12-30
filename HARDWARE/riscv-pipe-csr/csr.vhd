--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- processor_common.vhd - Common types and constants

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

entity csr is
    generic (freq_sys : integer := SYSTEM_FREQUENCY;
             freq_count : integer := CLOCK_FREQUENCY
         );
    port (clk : in std_logic;
          areset : in std_logic;
          csr_op : in csr_op_type;
          csr_addr : in csraddr_type;
          csr_datain : in data_type;
          csr_immrs1 : in csrimmrs1_type;
          csr_instret : in std_logic;
          csr_dataout : out data_type
         );
end entity csr;

architecture rtl of csr is
signal csr : csr_type;
signal csr_addr_int : integer range 0 to 2**csr_size_bits-1;

constant rdcycle_addr : integer := 3072; -- c00
constant rdtime_addr : integer := 3073; -- c01
constant rdinstret_addr : integer := 3074; -- c02
constant rdcycleh_addr : integer := 3200; -- c80
constant rdtimeh_addr : integer := 3201; -- c81
constant rdinstreth_addr : integer := 3202; --c82

constant rwtest_addr : integer := 3072+31; -- c1f
constant rwtesth_addr : integer := 3200+31; -- c9f

begin

    -- Fetch CSR address
    csr_addr_int <= to_integer(unsigned(csr_addr));
    
    -- Output the pointed CSR
    process (csr_addr_int, csr_op, csr) is
    begin
        if csr_op /= csr_nop then
            csr_dataout <= csr(csr_addr_int);
        else
            csr_dataout <= (others => 'X');
        end if;
    end process;
    
    -- RDCYCLE --- count the number of clock cycles
    -- These are read-only registers
    process (clk, areset) is
    variable rdcycle_reg : unsigned(63 downto 0);
    begin
        if areset = '1' then
            rdcycle_reg := (others => '0');
        elsif rising_edge(clk) then
            rdcycle_reg := rdcycle_reg + 1;
        end if;
        csr(rdcycle_addr) <= std_logic_vector(rdcycle_reg(31 downto 0));
        csr(rdcycleh_addr) <= std_logic_vector(rdcycle_reg(63 downto 32));
    end process;
    
    -- RDTIME --- count the number of microseconds
    -- These are read-only registers
    process (clk, areset) is
    variable rdtime_reg : unsigned(63 downto 0);
    variable prescaler : integer range 0 to freq_sys/freq_count-1;
    begin
        if areset = '1' then
            rdtime_reg := (others => '0');
            prescaler := 0;
        elsif rising_edge(clk) then
            if prescaler = freq_sys/freq_count-1 then
                prescaler := 0;
                rdtime_reg := rdtime_reg + 1;
            else
                prescaler := prescaler + 1;
            end if;
        end if;
        csr(rdtime_addr) <= std_logic_vector(rdtime_reg(31 downto 0));
        csr(rdtimeh_addr) <= std_logic_vector(rdtime_reg(63 downto 32));
    end process;
    
    -- RDINSTRET --- instructions retired
    -- These are read-only registers
    process (clk, areset) is
    variable rdinstret_reg : unsigned(63 downto 0);
    begin
        if areset = '1' then
            rdinstret_reg := (others => '0');
        elsif rising_edge(clk) then
            if csr_instret = '1' then
                rdinstret_reg := rdinstret_reg + 1;
            end if;
        end if;
        csr(rdinstret_addr) <= std_logic_vector(rdinstret_reg(31 downto 0));
        csr(rdinstreth_addr) <= std_logic_vector(rdinstret_reg(63 downto 32));
    end process;

    -- RWTEST -- read/write test registers
    process (clk, areset) is
    begin
        if areset = '1' then
            csr(rwtest_addr) <= (others => '0');
            csr(rwtesth_addr) <= (others => '0');
        elsif rising_edge(clk) then
            if csr_addr_int = rwtest_addr then
                case csr_op is
                    when csr_rw =>
                        csr(rwtest_addr) <= csr_datain;
                    when csr_rs =>
                        for i in 31 downto 0 loop
                            if csr_datain(i) = '1' then
                                csr(rwtest_addr)(i) <= '1';
                            end if;
                        end loop;
                    when csr_rc =>
                        for i in 31 downto 0 loop
                            if csr_datain(i) = '1' then
                                csr(rwtest_addr)(i) <= '0';
                            end if;
                        end loop;
                    when csr_rwi =>
                        csr(rwtest_addr)(31 downto 5) <= (others => '0');
                        csr(rwtest_addr)(4 downto 0) <= csr_immrs1;
                    when csr_rsi =>
                        for i in 4 downto 0 loop
                            if csr_immrs1(i) = '1' then
                                csr(rwtest_addr)(i) <= '1';
                            end if;
                        end loop;
                    when csr_rci =>
                        for i in 4 downto 0 loop
                            if csr_immrs1(i) = '1' then
                                csr(rwtest_addr)(i) <= '1';
                            end if;
                        end loop;
                    when others =>
                        null;
                end case;
            elsif csr_addr_int = rwtesth_addr then
                case csr_op is
                    when csr_rw =>
                        csr(rwtesth_addr) <= csr_datain;
                    when csr_rs =>
                        for i in 31 downto 0 loop
                            if csr_datain(i) = '1' then
                                csr(rwtesth_addr)(i) <= '1';
                            end if;
                        end loop;
                    when csr_rc =>
                        for i in 31 downto 0 loop
                            if csr_datain(i) = '1' then
                                csr(rwtesth_addr)(i) <= '0';
                            end if;
                        end loop;
                    when csr_rwi =>
                        csr(rwtesth_addr)(31 downto 5) <= (others => '0');
                        csr(rwtesth_addr)(4 downto 0) <= csr_immrs1;
                    when csr_rsi =>
                        for i in 4 downto 0 loop
                            if csr_immrs1(i) = '1' then
                                csr(rwtesth_addr)(i) <= '1';
                            end if;
                        end loop;
                    when csr_rci =>
                        for i in 4 downto 0 loop
                            if csr_immrs1(i) = '1' then
                                csr(rwtesth_addr)(i) <= '1';
                            end if;
                        end loop;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
    
end architecture rtl;