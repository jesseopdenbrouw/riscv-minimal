--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
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

-- Set the bit time
constant bittime : time := (1000000000/115200) * 1 ns;
-- Select 7, 8 or 9 bits
constant chartosend : std_logic_vector := "1000001";

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
    begin
        -- Reset is active low
        areset <= '0';
        -- RxD input is idle high
        RxD <= '1';
        pina <= x"ffffff40";
        wait for 25 ns;
        areset <= '1';
        --wait for 2090 ns;
        wait for 55*20 ns;
        pina <= x"ffffff41";
        wait for 20 ns;
        pina <= x"ffffff40";
        
        wait for 500 us;
        
        -- Send start bit
        -- Transmission speed is slightly
        -- faster than 115200 bps
        RxD <= '0';
        wait for bittime;
        -- Send character
        for i in 0 to chartosend'high loop
            RxD <= chartosend(i);
            wait for bittime;
        end loop;
        -- Send parity bit
        RxD <= '0';
        wait for bittime;
        -- Send stop bit
        RxD <= '1';
        wait for bittime;
        
        wait;
        
    end process;
    
end architecture sim;