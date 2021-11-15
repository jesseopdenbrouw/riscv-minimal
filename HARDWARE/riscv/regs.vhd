--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- regs.vhd - The register file, Big Endian

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

entity regs is
    port (
        clk : in std_logic;
        areset : in std_logic;
        datain : in data_type;
        selrd  : in reg_type;
        enable : in std_logic;
        sel1out : in reg_type;
        sel2out : in reg_type;
        sel3out : in reg_type;
        sel4out : in reg_type;
        rs1out : out data_type;
        rs2out : out data_type;
        rs3out : out data_type;
        rs4out : out data_type
       );
end entity regs;

architecture rtl of regs is
type regs_array_type is array (0 to 31) of std_logic_vector(31 downto 0);
signal regs_int : regs_array_type;
begin
    
    process (clk, areset, selrd, sel1out, sel2out, sel3out, sel4out, regs_int) is
    variable selrd_int : integer;
    variable selaout_int : integer;
    variable selbout_int : integer;
    variable selcout_int : integer;
    variable seldout_int : integer;
    begin
        selrd_int := to_integer(unsigned(selrd));
        selaout_int := to_integer(unsigned(sel1out));
        selbout_int := to_integer(unsigned(sel2out));
        selcout_int := to_integer(unsigned(sel3out));
        seldout_int := to_integer(unsigned(sel4out));
        
        if areset = '1' then
            regs_int <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if enable = '1' then
                regs_int(selrd_int) <= datain;
            end if;
        end if;
        -- Register 0 is always 0x00000000
        -- Synthesizer with remove this register
        regs_int(0) <= (others => '0');
        
        rs1out <= regs_int(selaout_int);
        rs2out <= regs_int(selbout_int);
        rs3out <= regs_int(selcout_int);
        rs4out <= regs_int(seldout_int);
    end process;

end architecture rtl;