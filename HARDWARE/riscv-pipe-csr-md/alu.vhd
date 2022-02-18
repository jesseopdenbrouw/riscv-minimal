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

-- The Arithmetic and Logic Unit. It is pure combinational
-- logic that performs the desired operation. It also
-- computes if a branch should be taken.

-- There arw two achitecture: a default, not optimized version
-- and an optimzed version. The non-optimized version is best
-- to read because of its clariry. However this version created
-- a *lot* of hardware, especially for the shift operations.
-- The optimized version is harder to read but reduces the
-- amount of hardware drastically (again, especially for the
-- shift operations).

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
        csr : in data_type;
        mul : in data_type;
        div : in data_type;
        result : out data_type
       );
end entity alu;

-- The default, non-optimized architecture
architecture rtl of alu is
begin

    process (alu_op, dataa, datab, immediate, shift, pc, memory, csr, mul, div) is
    variable a, b, r, im : unsigned(31 downto 0);
    variable as, bs, ims : signed(31 downto 0);
    variable shamt : integer range 0 to 31;
    begin
        a := unsigned(dataa);
        b := unsigned(datab);
        r := (others => '0');
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

            -- Jumps and calls
            -- PC is already 4 bytes ahead
            when alu_jal =>
                r := unsigned(pc);
            when alu_jalr =>
                r := unsigned(pc);
            
            -- Branches
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

            -- Pass data from CSR
            when alu_csr =>
                r := unsigned(csr);
            -- Pass data from multiplier
            when alu_mul|alu_mulh|alu_mulhsu|alu_mulhu =>
                r := unsigned(mul);
            
            -- Pass data from divider
            when alu_div|alu_divu|alu_rem|alu_remu =>
                r := unsigned(div);
                
            when others =>
                r := (others => 'X');
        end case;
        result <= std_logic_vector(r);
    end process;
end architecture rtl;

-- The optimzed architecture
architecture optimized_rtl of alu is
begin

    process (alu_op, dataa, datab, immediate, shift, pc, memory, csr, mul, div) is
    variable a, b, r, im : unsigned(31 downto 0);
    variable as, bs, ims : signed(31 downto 0);
    variable shamt : integer range 0 to 31;
    constant zeros : unsigned(31 downto 0) := (others => '0');
    variable signs : unsigned(31 downto 0);
    begin
        a := unsigned(dataa);
        b := unsigned(datab);
        r := (others => '0');
        as := signed(dataa);
        bs := signed(datab);
        case alu_op is
            -- No operation
            when alu_nop =>
                r := (others => 'X');

            -- Arithmetic and logic
            when alu_add|alu_addi|alu_sub =>
                if alu_op = alu_addi then
                    b(31 downto 12) := (others => immediate(11));
                    b(11 downto 0) := unsigned(immediate(11 downto 0));
                elsif alu_op = alu_sub then
                    -- Do the two's complement trick
                    b := not(b) + 1;
                end if;
                r := a + b;
            when alu_and|alu_andi =>
                if alu_op = alu_andi then
                    b(31 downto 12) := (others => immediate(11));
                    b(11 downto 0) := unsigned(immediate(11 downto 0));
                end if;
                r := a and b;
            when alu_or|alu_ori =>
                if alu_op = alu_ori then
                    b(31 downto 12) := (others => immediate(11));
                    b(11 downto 0) := unsigned(immediate(11 downto 0));
                end if;
                r := a or b;
            when alu_xor|alu_xori =>
                if alu_op = alu_xori then
                    b(31 downto 12) := (others => immediate(11));
                    b(11 downto 0) := unsigned(immediate(11 downto 0));
                end if;
                r := a xor b;

            -- Shifts et al
            when alu_sll|alu_slli =>
                if alu_op = alu_slli then
                    b(4 downto 0) := unsigned(shift(4 downto 0));
                end if;
                if b(4) = '1' then
                    a := a(15 downto 0) & zeros(15 downto 0);
                end if;
                if b(3) = '1' then
                    a := a(23 downto 0) & zeros(7 downto 0);
                end if;
                if b(2) = '1' then
                    a := a(27 downto 0) & zeros(3 downto 0);
                end if;
                if b(1) = '1' then
                    a := a(29 downto 0) & zeros(1 downto 0);
                end if;
                if b(0) = '1' then
                    a := a(30 downto 0) & zeros(0 downto 0);
                end if;
                r := a;
            when alu_srl|alu_srli =>
                if alu_op = alu_srli then
                    b(4 downto 0) := unsigned(shift(4 downto 0));
                end if;
                if b(4) = '1' then
                    a := zeros(15 downto 0) & a(31 downto 16);
                end if;
                if b(3) = '1' then
                    a := zeros(7 downto 0) & a(31 downto 8);
                end if;
                if b(2) = '1' then
                    a := zeros(3 downto 0) & a(31 downto 4);
                end if;
                if b(1) = '1' then
                    a := zeros(1 downto 0) & a(31 downto 2);
                end if;
                if b(0) = '1' then
                    a := zeros(0 downto 0) & a(31 downto 1);
                end if;
                r := a;
            when alu_sra|alu_srai =>
                if alu_op = alu_srai then
                    b(4 downto 0) := unsigned(shift(4 downto 0));
                end if;
                signs := (others => a(31));
                if b(4) = '1' then
                    a := signs(15 downto 0) & a(31 downto 16);
                end if;
                if b(3) = '1' then
                    a := signs(7 downto 0) & a(31 downto 8);
                end if;
                if b(2) = '1' then
                    a := signs(3 downto 0) & a(31 downto 4);
                end if;
                if b(1) = '1' then
                    a := signs(1 downto 0) & a(31 downto 2);
                end if;
                if b(0) = '1' then
                    a := signs(0 downto 0) & a(31 downto 1);
                end if;
                r := a;

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

            -- Jumps and calls
            -- PC is already 4 bytes ahead
            when alu_jal|alu_jalr =>
                r := unsigned(pc);
            
            -- Test register & immediate signed/unsigned
            when alu_slti =>
                ims(31 downto 12) := (others => immediate(11));
                ims(11 downto 0) := signed(immediate(11 downto 0));
                r := (others => '0');
                if as < ims then
                    r(0) := '1';
                end if;
            when alu_sltiu =>
                im(31 downto 12) := (others => immediate(11));
                im(11 downto 0) := unsigned(immediate(11 downto 0));
                r := (others => '0');
                if a < im then
                    r(0) := '1';
                end if;

            -- Branches and tests
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
            when alu_blt|alu_slt =>
                r := (others => '0');
                if as < bs then
                    r(0) := '1';
                end if;
            when alu_bge =>
                r := (others => '0');
                if as >= bs then
                    r(0) := '1';
                end if;
            when alu_bltu|alu_sltu =>
                r := (others => '0');
                if a < b then
                    r(0) := '1';
                end if;
            when alu_bgeu =>
                r := (others => '0');
                if a >= b then
                    r(0) := '1';
                end if;

            -- Pass data from CSR
            when alu_csr =>
                r := unsigned(csr);

            -- Pass data from multiplier
            when alu_mul|alu_mulh|alu_mulhsu|alu_mulhu =>
                r := unsigned(mul);

                -- Pass data from divider
            when alu_div|alu_divu|alu_rem|alu_remu =>
                r := unsigned(div);
                
            when others =>
                r := (others => 'X');
        end case;
        result <= std_logic_vector(r);
    end process;
end architecture optimized_rtl;
