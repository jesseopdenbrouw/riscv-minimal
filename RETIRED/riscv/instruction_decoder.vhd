--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- instruction_decoder.vhd - The Instruction Decoder

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

entity instruction_decoder is
    port (clk : in std_logic;
          areset : in std_logic;
          waitfordata : in std_logic;
          instr : in data_type;
          alu_op : out alu_op_type;
          rd : out reg_type;
          rd_enable : out std_logic;
          rs1 : out reg_type;
          rs2 : out reg_type;
          shift : out shift_type;
          immediate : out data_type;
          size : out size_type;
          offset : out data_type; 
          pc_op : out pc_op_type;
          memaccess : out memaccess_type;
          error : out std_logic
         );
end entity instruction_decoder;

architecture rtl of instruction_decoder is
-- Some aliases for easy handling
alias opcode : opcode_type is instr(6 downto 0);
alias func3 : func3_type is instr(14 downto 12);
alias func7 : func7_type is instr(31 downto 25);
alias rd_i : reg_type is instr(11 downto 7);
alias rs1_i : reg_type is instr(19 downto 15);
alias rs2_i : reg_type is instr(24 downto 20);
alias shamt : shift_type is instr(24 downto 20);
type state_type is (state_unknown, state_fetch, state_execute, state_wait);
signal state : state_type;
begin

    process (clk, areset) is
    begin
        if areset = '1' then
            state <= state_fetch;
        elsif rising_edge(clk) then
            case state is
                when state_fetch =>
                    state <= state_execute;
                when state_execute =>
                    if waitfordata = '1' then
                        state <= state_wait;
                    else
                        state <= state_fetch;
                    end if;
                when state_wait =>
                    state <= state_fetch;
                when others =>
                    state <= state_fetch;
            end case;
        end if;
    end process;

    process (instr, state, waitfordata) is
    begin
        -- Set defaults
        alu_op <= alu_nop;
        rd <= (others => '-');
        rd_enable <= '0';
        rs1 <= (others => '-');
        rs2 <= (others => '-');
        shift <= (others => '-');
        immediate <= (others => '-');
        size <= size_unknown;
        offset <= (others => '-');
        pc_op <= pc_incr;
        memaccess <= memaccess_nop;
        error <= '0';
        
        case state is
        when state_fetch =>
            pc_op <= pc_hold;
        when state_execute =>
            -- Parse opcodes
            case opcode is
                -- LUI
                when "0110111" =>
                    alu_op <= alu_lui;
                    rd <= rd_i;
                    rd_enable <= '1';
                    immediate(31 downto 12) <= instr(31 downto 12);
                    immediate(11 downto 0) <= (others => '0');
                -- AUIPC
                when "0010111" =>
                    alu_op <= alu_auipc;
                    rd <= rd_i;
                    rd_enable <= '1';
                    immediate(31 downto 12) <= instr(31 downto 12);
                    immediate(11 downto 0) <= (others => '0');
                -- JAL
                when "1101111" =>
                    alu_op <= alu_jal;
                    pc_op <= pc_loadoffset;
                    rd <= rd_i;
                    rs1 <= rs1_i;
                    rd_enable <= '1';
                    offset <= (0 => '0', others => instr(31));
                    offset(20 downto 1) <= instr(31) & instr(19 downto 12) &  instr(20) & instr(30 downto 21);
                    offset(0) <= '0';
                -- JALR
                when "1100111" =>
                    if func3 = "000" then
                        alu_op <= alu_jalr;
                        pc_op <= pc_loadoffsetregister;
                        rd <= rd_i;
                        rs1 <= rs1_i;
                        rd_enable <= '1';
                        offset <= (0 => '0', others => instr(31));
                        offset(11 downto 0) <= instr(31 downto 20);
                    else
                        error <= '1';
                    end if;
                -- Branches
                when "1100011" =>
                    -- Set the register to compare. Comparison is handled by the ALU.
                    rs1 <= rs1_i; rs2 <= rs2_i;
                    offset <= (0 => '0', others => instr(31));
                    offset(12 downto 1) <= instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8);
                    pc_op <= pc_branch;
                    case func3 is
                        when "000" => alu_op <= alu_beq;
                        when "001" => alu_op <= alu_bne;
                        when "100" => alu_op <= alu_blt;
                        when "101" => alu_op <= alu_bge;
                        when "110" => alu_op <= alu_bltu;
                        when "111" => alu_op <= alu_bgeu;
                        when others =>
                            -- Reset defaults
                            rs1 <= (others => '-'); rs2 <= (others => '-');
                            offset <= (others => '-');
                            pc_op <= pc_incr;
                            error <= '1';
                    end case;
                -- L{W|H|B|HU|BU}
                when "0000011" =>
                    case func3 is
                        -- LB
                        when "000" =>
                            alu_op <= alu_lb;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_byte;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                            if waitfordata = '1' then
                                pc_op <= pc_hold;
                                alu_op <= alu_nop;
                                rd <= (others => '-');
                                rd_enable <= '0';
                            end if;
                        -- LH
                        when "001" =>
                            alu_op <= alu_lh;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_halfword;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                            if waitfordata = '1' then
                                pc_op <= pc_hold;
                                alu_op <= alu_nop;
                                rd <= (others => '-');
                                rd_enable <= '0';
                            end if;
                        -- LW
                        when "010" =>
                            alu_op <= alu_lw;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_word;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                            if waitfordata = '1' then
                                pc_op <= pc_hold;
                                alu_op <= alu_nop;
                                rd <= (others => '-');
                                rd_enable <= '0';
                            end if;
                        -- LBU
                        when "100" =>
                            alu_op <= alu_lbu;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_byte;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                            if waitfordata = '1' then
                                pc_op <= pc_hold;
                                alu_op <= alu_nop;
                                rd <= (others => '-');
                                rd_enable <= '0';
                            end if;
                        -- LHU
                        when "101" =>
                            alu_op <= alu_lhu;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_halfword;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                            if waitfordata = '1' then
                                pc_op <= pc_hold;
                                alu_op <= alu_nop;
                                rd <= (others => '-');
                                rd_enable <= '0';
                            end if;
                        when others =>
                            error <= '1';
                    end case;
                -- S(W|H|B)
                when "0100011" =>
                    case func3 is
                        -- Store byte (no sign extension of zero extension)
                        when "000" =>
                            alu_op <= alu_nop;
                            memaccess <= memaccess_write;
                            size <= size_byte;
                            rs1 <= rs1_i;
                            rs2 <= rs2_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 25) & instr(11 downto 7);
                        -- Store halfword (no sign extension of zero extension)
                        when "001" =>
                            alu_op <= alu_nop;
                            memaccess <= memaccess_write;
                            size <= size_halfword;
                            rs1 <= rs1_i;
                            rs2 <= rs2_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 25) & instr(11 downto 7);
                        -- Store word
                        when "010" =>
                            alu_op <= alu_nop;
                            memaccess <= memaccess_write;
                            size <= size_word;
                            rs1 <= rs1_i;
                            rs2 <= rs2_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 25) & instr(11 downto 7);
                        when others =>
                            error <= '1';
                    end case;
                -- Arithmetic/logic register/immediate
                when "0010011" =>
                    -- ADDI
                    if func3 = "000" then
                        alu_op <= alu_addi;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => instr(31));
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- SLTI
                    elsif func3 = "010" then
                        alu_op <= alu_slti;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => instr(31));
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- SLTIU
                    elsif func3 = "011" then
                        alu_op <= alu_sltiu;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => '0');
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- XORI
                    elsif func3 = "100" then
                        alu_op <= alu_xori;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => instr(31));
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- ORI
                    elsif func3 = "110" then
                        alu_op <= alu_ori;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => instr(31));
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- ANDI
                    elsif func3 = "111" then
                        alu_op <= alu_andi;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        immediate <= (others => instr(31));
                        immediate(11 downto 0) <= instr(31 downto 20);
                    -- SLLI
                    elsif func3 = "001" and func7 = "0000000" then
                        alu_op <= alu_slli;
                        rd <= rd_i;
                        rd_enable <= '1';
                        shift <= shamt;
                        rs1 <= rs1_i;
                        rd <= rd_i;
                    -- SRLI
                    elsif func3 = "101" and func7 = "0000000" then
                        alu_op <= alu_srli;
                        rd <= rd_i;
                        rd_enable <= '1';
                        shift <= shamt;
                        rs1 <= rs1_i;
                        rd <= rd_i;
                    -- SRAI
                    elsif func3 = "101" and func7 = "0100000" then
                        alu_op <= alu_srai;
                        rd <= rd_i;
                        rd_enable <= '1';
                        shift <= shamt;
                        rs1 <= rs1_i;
                        rd <= rd_i;
                    else
                        error <= '1';
                    end if;
                -- Arithmetic/logic register/register
                when "0110011" =>
                    -- ADD
                    if func3 = "000" and func7 = "0000000" then
                        alu_op <= alu_add;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SUB
                    elsif func3 = "000" and func7 = "0100000" then
                        alu_op <= alu_sub;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SLL
                    elsif func3 = "001" and func7 = "0000000" then
                        alu_op <= alu_sll; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SLT
                    elsif func3 = "010" and func7 = "0000000" then
                        alu_op <= alu_slt; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SLTU
                    elsif func3 = "011" and func7 = "0000000" then
                        alu_op <= alu_sltu; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- XOR
                    elsif func3 = "100" and func7 = "0000000" then
                        alu_op <= alu_xor; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SRL
                    elsif func3 = "101" and func7 = "0000000" then
                        alu_op <= alu_srl; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- SRA
                    elsif func3 = "101" and func7 = "0100000" then
                        alu_op <= alu_sra; 
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- OR
                    elsif func3 = "110" and func7 = "0000000" then
                        alu_op <= alu_or;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    -- AND
                    elsif func3 = "111" and func7 = "0000000" then
                        alu_op <= alu_and;
                        rd <= rd_i;
                        rd_enable <= '1';
                        rs1 <= rs1_i;
                        rs2 <= rs2_i;
                    else
                        error <= '1';
                    end if;
                -- FENCE (not implemented)
                when "0001111" =>
                    if func3 = "000" then
                        null;
                    else
                        error <= '1';
                    end if;
                -- ECALL, EBREAK (not implemented)
                when "1110011" =>
                    -- better decoding needed
                    null;
                when others =>
                    error <= '1';
            end case;
        when state_wait =>
                -- L{W|H|B|HU|BU}
            case opcode is
                when "0000011" =>
                    case func3 is
                        -- LB
                        when "000" =>
                            alu_op <= alu_lb;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_byte;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                        -- LH
                        when "001" =>
                            alu_op <= alu_lh;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_halfword;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                        -- LW
                        when "010" =>
                            alu_op <= alu_lw;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_word;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                        -- LBU
                        when "100" =>
                            alu_op <= alu_lbu;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_byte;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                        -- LHU
                        when "101" =>
                            alu_op <= alu_lhu;
                            rd <= rd_i;
                            rd_enable <= '1';
                            memaccess <= memaccess_read;
                            size <= size_halfword;
                            rs1 <= rs1_i;
                            offset <= (others => instr(31));
                            offset(11 downto 0) <= instr(31 downto 20);
                        when others =>
                            error <= '1';
                    end case;
                when others =>
                    error <= '1';
            end case;
        when others =>
            null;
        end case;
    end process;
end architecture rtl;