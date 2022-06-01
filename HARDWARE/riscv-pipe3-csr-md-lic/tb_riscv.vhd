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
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pina : in data_type;
          O_pouta : out data_type;
          I_RxD : in std_logic;
          O_TxD : out std_logic
         );
end component riscv;

signal clk : std_logic;
signal areset : std_logic;
signal pina : data_type;
signal pouta : data_type;
signal TxD, RxD : std_logic;

-- Set the bit time
constant bittime : time := (1000000000/9600) * 1 ns;
-- Select 7, 8 or 9 bits
constant chartosend : std_logic_vector := "01000001";

begin

    -- Instantiate the processor
    dut : riscv
    port map (I_clk => clk, I_areset => areset, I_pina => pina, O_pouta => pouta, I_RxD => RxD, O_TxD => TxD);
    
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
        wait for 15 ns;
        areset <= '1';
        --wait for 40000 ns;
        wait for 24*20 ns;
        pina <= x"ffffff41";
        wait for 1*20 ns;
        --wait for 20000 ns;
        pina <= x"ffffff40";
        
        wait for 500 us;
        
        -- Send start bit
        -- Transmission speed is slightly
        -- faster than 9600 bps
        RxD <= '0';
        wait for bittime;
        -- Send character
        for i in chartosend'high downto 0 loop
            RxD <= chartosend(i);
            wait for bittime;
        end loop;
--        -- Send parity bit
--        RxD <= '0';
--        -- Send stop bit
        wait for bittime;
        RxD <= '1';
        wait for bittime;
        
        wait;
        
    end process;
    
end architecture sim;