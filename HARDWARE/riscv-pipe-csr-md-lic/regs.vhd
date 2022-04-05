--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- regs.vhd - The register file, Big Endian

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The register file with 16 or 32 registers depending on the
-- setting in the processor_common.vhd file. 32 registers for
-- rv32i and 16 registers for rv32e. Note that register 0 (x0)
-- is hardwired to all zeros. Reading this register supplies
-- all zero bits and writing this register has no effect.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity regs is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_datain : in data_type;
          I_selrd  : in reg_type;
          I_enable : in std_logic;
          I_sel1out : in reg_type;
          I_sel2out : in reg_type;
          O_rs1out : out data_type;
          O_rs2out : out data_type
         );
end entity regs;

architecture rtl of regs is
type regs_array_type is array (0 to NUMBER_OF_REGISTERS-1) of std_logic_vector(31 downto 0);
signal regs_int : regs_array_type;
begin
    
    process (I_clk, I_areset, I_selrd, I_sel1out, I_sel2out, regs_int) is
    variable selrd_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    variable selaout_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    variable selbout_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    begin
        selrd_int := to_integer(unsigned(I_selrd));
        selaout_int := to_integer(unsigned(I_sel1out));
        selbout_int := to_integer(unsigned(I_sel2out));
        
        if I_areset = '1' then
            regs_int <= (others => (others => '0'));
        elsif rising_edge(I_clk) then
            if I_enable = '1' then
                regs_int(selrd_int) <= I_datain;
            end if;
        end if;
        -- Register 0 is always 0x00000000
        -- Synthesizer with remove this register
        regs_int(0) <= (others => '0');
        
        O_rs1out <= regs_int(selaout_int);
        O_rs2out <= regs_int(selbout_int);
    end process;

end architecture rtl;