--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- alu.vhd - The Arithmetic and Logic Unit, Big Endian

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

entity alu is
    port (
        alu_op : in alu_op_type;
        dataa : in data_type;
        datab : in data_type;
        immediate : in data_type;
        shift: in shift_type;
        pc : in data_type;
        memory : in data_type;
        result : out data_type
       );
end entity alu;

architecture rtl of alu is
begin

    process (alu_op, dataa, datab, immediate, shift, pc, memory) is
    variable a, b, r, im : unsigned(31 downto 0);
    variable as, bs, ims : signed(31 downto 0);
    variable shamt : integer range 0 to 31;
    begin
        a := unsigned(dataa);
        b := unsigned(datab);
        as := signed(dataa);
        bs := signed(datab);
        case alu_op is
            -- No operation
            when alu_nop =>
                r := (others => 'X');
                
            -- Arithmetic & logic registers
            when alu_add =>
                r := a + b;
            when alu_sub =>
                -- use two's complement trickery
                r := a + not(b) + 1;
            when alu_and =>
                r := a and b;
            when alu_or =>
                r := a or b;
            when alu_xor =>
                r := a xor b;

            -- Test registers signed/unsigned
            when alu_slt =>
                if as < bs then
                    r := (0 => '1', others => '0');
                else
                    r := (others => '0');
                end if;
            when alu_sltu =>
                if a < b then
                    r := (0 => '1', others => '0');
                else
                    r := (others => '0');
                end if;

            -- Arithmetic & logic register with immediate
            when alu_addi =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                r := a + im;
            when alu_andi =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                r := a and im;
            when alu_ori =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                r := a or im;
            when alu_xori =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                r := a xor im;

            -- Test register & immediate signed/unsigned
            when alu_slti =>
                ims(31 downto 12) := (others => immediate(11));
                ims(11 downto 0) := signed(immediate(11 downto 0));
                if as < ims then
                    r := (0 => '1', others => '0');
                else
                    r := (others => '0');
                end if;
            when alu_sltiu =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                if a < im then
                    r := (0 => '1', others => '0');
                else
                    r := (others => '0');
                end if;

            -- Shifts et al
            when alu_sll =>
                r := (others => '0');
                shamt := to_integer(unsigned(b(4 downto 0)));
                r(31 downto shamt) := a(31-shamt downto 0);
            when alu_srl =>
                r := (others => '0');
                shamt := to_integer(unsigned(b(4 downto 0)));
                r(31-shamt downto 0) := a(31 downto shamt);
            when alu_sra =>
                r := (others => a(31));
                shamt := to_integer(unsigned(b(4 downto 0)));
                r(31-shamt downto 0) := a(31 downto shamt);
                
            when alu_slli =>
                r := (others => '0');
                shamt := to_integer(unsigned(shift));
                r(31 downto shamt) := a(31-shamt downto 0);
            when alu_srli =>
                r := (others => '0');
                shamt := to_integer(unsigned(shift));
                r(31-shamt downto 0) := a(31 downto shamt);
            when alu_srai =>
                r := (others => a(31));
                shamt := to_integer(unsigned(shift));
                r(31-shamt downto 0) := a(31 downto shamt);
                
            -- Loads etc
            when alu_lui =>
                r := unsigned(immediate);
                r(11 downto 0) := (others => '0');
            when alu_auipc =>
                r := unsigned(immediate);
                r(11 downto 0) := (others => '0');
                r := r + unsigned(pc) - 4 ;
            when alu_lw =>
                r := unsigned(memory);
            when alu_lh =>
                r := (others => memory(15));
                r(15 downto 0) := unsigned(memory(15 downto 0));
            when alu_lhu =>
                r := (others => '0');
                r(15 downto 0) := unsigned(memory(15 downto 0));
            when alu_lb =>
                r := (others => memory(7));
                r(7 downto 0) := unsigned(memory(7 downto 0));
            when alu_lbu =>
                r := (others => '0');
                r(7 downto 0) := unsigned(memory(7 downto 0));

            when alu_jal =>
                r := unsigned(pc);
            when alu_jalr =>
                r := unsigned(pc);
                
            when alu_beq =>
                r := (others => '0');
                if a = b then
                    r(0) := '1';
                end if;
            when alu_bne =>
                r := (others => '0');
                if a /= b then
                    r(0) := '1';
                end if;
            when alu_blt =>
                r := (others => '0');
                if as < bs then
                    r(0) := '1';
                end if;
            when alu_bge =>
                r := (others => '0');
                if as >= bs then
                    r(0) := '1';
                end if;
            when alu_bltu =>
                r := (others => '0');
                if a < b then
                    r(0) := '1';
                end if;
            when alu_bgeu =>
                r := (others => '0');
                if a >= b then
                    r(0) := '1';
                end if;
                
            when others =>
                r := (others => 'X');
        end case;
        result <= std_logic_vector(r);
    end process;
end architecture rtl;