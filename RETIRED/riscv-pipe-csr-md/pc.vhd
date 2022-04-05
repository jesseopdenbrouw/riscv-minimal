--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- pc.vhd - The Program Counter, Big Endian

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

entity pc is
    port (
        clk : in std_logic;
        areset : in std_logic;
        pc_op : in pc_op_type;
        rs : in data_type;
        offset : in data_type;
        branch : in std_logic;
        address : out data_type;
        misaligned_error : out std_logic
       );
end entity pc;

architecture rtl of pc is
signal pc_int : unsigned(31 downto 0);
begin

    process (clk, areset, pc_int) is
    constant rom_high_nibble_int : unsigned(3 downto 0) := unsigned(rom_high_nibble);
    begin
        if areset = '1' then
            pc_int <= (others => '0');
            pc_int(31 downto 28) <= rom_high_nibble_int;
        elsif rising_edge(clk) then
            case pc_op is
                when pc_hold =>
                    -- Hold the PC
                    null;
                when pc_incr =>
                    -- Next instruction address
                    pc_int <= pc_int + 4;
                when pc_loadoffset =>
                    -- Current PC + offset, but PC is 4 too far,
                    -- so compensate for that
                    pc_int <= pc_int - 4 + unsigned(offset);
                when pc_loadoffsetregister =>
                    -- Jump to register contents AND offset
                    pc_int <= unsigned(offset) + unsigned(rs);
                when pc_branch =>
                    -- Check if branch (conditional)
                    if branch = '1' then
                        -- If yes, then branch, but PC is 4 too far,
                        -- so compensate for that
                        pc_int <= pc_int - 4 + unsigned(offset);
                    else
                        -- Continue to next instruction
                        pc_int <= pc_int + 4;
                    end if;
                when others =>
                    null;
            end case;
        end if;
        address <= std_logic_vector(pc_int);
        if pc_int(1 downto 0) /= "00" then
            misaligned_error <= '1';
        else
            misaligned_error <= '0';
        end if;
    end process;
end architecture rtl;
       