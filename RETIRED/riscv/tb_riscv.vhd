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
           pina : in data_type;
           pouta : out data_type;
           TxD : out std_logic;
           RxD : in std_logic
         );
end component riscv;

signal clk : std_logic;
signal areset : std_logic;
signal pina : data_type;
signal pouta : data_type;
signal TxD, RxD : std_logic;

begin

    -- Instantiate the processor
    dut : riscv
    port map (clk => clk, areset => areset, pina => pina, pouta => pouta, TxD => TxD, RxD => RxD);
    
    -- Generate a symmetric clock signal, 50 MHz
    process is
    begin
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
    end process;
    
    -- Only here to supply a reset, datain and RxD
    process is
    constant chartosend : std_logic_vector(7 downto 0) := "01000001";
    begin
        -- Reset is active low
        areset <= '0';
        -- RxD input is idle high
        RxD <= '1';
        pina <= x"ffffffff";
        wait for 25 ns;
        areset <= '1';
        wait for 1000 us;
        
        -- Send start bit
        -- Transmission speed is slightly
        -- faster than 9600 bps
        RxD <= '0';
        wait for 104 us;
        -- Send character
        for i in 0 to 7 loop
            RxD <= chartosend(i);
            wait for 104 us;
        end loop;
        -- Send stop bit
        RxD <= '1';
        wait for 104 us;
        
        wait;
        
    end process;
    
end architecture sim;