--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- tb_riscv.vhd - VHDL Test Bench file

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

entity tb_riscv is
end entity tb_riscv;

architecture sim of tb_riscv is

component riscv is
    port ( clk : in std_logic;
           areset : in std_logic;
           datain : in data_type;
           dataout : out data_type
         );
end component riscv;

signal clk : std_logic;
signal areset : std_logic;
signal datain : data_type;
signal dataout : data_type;

begin

    -- Instantiate the processor
    dut : riscv
    port map (clk => clk, areset => areset, datain => datain, dataout => dataout);
    
    -- Generate a symmetric clock signal, 100 MHz
    process is
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;
    
    -- Only here to supply a reset and datain
    process is
    begin
        -- Reset is active low
        areset <= '0';
        datain <= x"ffffffff";
        wait for 12 ns;
        areset <= '1';
        wait;
    end process;
    
end architecture sim;