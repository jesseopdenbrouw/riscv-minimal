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
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- PC operation
          I_pc_op : in pc_op_type;
          -- Register data to load
          I_rs : in data_type;
          -- Offset from ....
          I_offset : in data_type;
          -- Should we branch?
          I_branch : in std_logic;
          -- For loading mtvec
          I_mtvec : in data_type;
          -- For loading mepc
          I_mepc : in data_type;
          -- Should we restart the instruction?
          I_restart_instruction : in std_logic;
          -- The current value of the PC
          O_pc : out data_type;
          -- The PC for CSR mepc
          O_pc_to_mepc : out data_type;
          -- PC to save. This is the real PC to save, not what mepc tells us.
          O_pc_to_save : out data_type;
          -- Instruction misaligned (PC not on 4-byte boundary)
          O_instruction_misaligned_error : out std_logic
       );
end entity pc;

architecture rtl of pc is
signal pc_int : unsigned(31 downto 0);
signal pc_prev_int : unsigned(31 downto 0);
begin

    process (I_clk, I_areset, pc_int) is
    constant rom_high_nibble_int : unsigned(3 downto 0) := unsigned(rom_high_nibble);
    begin
        if I_areset = '1' then
            pc_int <= (others => '0');
            pc_int(31 downto 28) <= rom_high_nibble_int;
            pc_prev_int <= (others => '0');
            pc_prev_int(31 downto 28) <= rom_high_nibble_int;
        elsif rising_edge(I_clk) then
            case I_pc_op is
                when pc_hold =>
                    -- Hold the PC
                    null;
                when pc_incr =>
                    -- Next instruction address
                    pc_int <= pc_int + 4;
                    pc_prev_int <= pc_int;
                when pc_loadoffset =>
                    -- Current PC + offset, but PC is 4 too far,
                    -- so compensate for that
                    pc_int <= pc_int - 4 + unsigned(I_offset);
                    pc_prev_int <= pc_int;
                when pc_loadoffsetregister =>
                    -- Jump to register contents AND offset
                    pc_int <= unsigned(I_offset) + unsigned(I_rs);
                    pc_prev_int <= pc_int;
                when pc_branch =>
                    -- Check if branch (conditional)
                    if I_branch = '1' then
                        -- If yes, then branch, but PC is 4 too far,
                        -- so compensate for that
                        pc_int <= pc_int - 4 + unsigned(I_offset);
                    else
                        -- Continue to next instruction
                        pc_int <= pc_int + 4;
                    end if;
                    pc_prev_int <= pc_int;
                when pc_load_mepc =>
                    -- Load the return address
                    pc_int <= unsigned(I_mepc);
                    pc_prev_int <= pc_int;
                when pc_load_mtvec =>
                    -- Load the trap vector address
                    pc_int <= unsigned(I_mtvec);
                    pc_prev_int <= pc_int;
                when others =>
                    null;
            end case;
        end if;

       
        -- Signal misaligned instruction, causes exeception
        if pc_int(1 downto 0) /= "00" then
            O_instruction_misaligned_error <= '1';
        else
            O_instruction_misaligned_error <= '0';
        end if;
    end process;

    -- The PC for instruction fetch
    O_pc <= std_logic_vector(pc_int);
    -- PC to save, needed to (re)start an instruction
    O_pc_to_save <= std_logic_vector(pc_prev_int) when I_restart_instruction = '1' else std_logic_vector(pc_int);
    -- The value of the PC to be loaded in mepc. Is the previous one. Needed for debug routines
    O_pc_to_mepc <= std_logic_vector(pc_prev_int);

end architecture rtl;
