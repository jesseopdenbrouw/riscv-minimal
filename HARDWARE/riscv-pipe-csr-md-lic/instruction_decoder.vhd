--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- instruction_decoder.vhd - The Instruction Decoder

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The description of the instruction decoder consists of an
-- FSM the keeps track of the state of the processor and a
-- combinational logic that provides the control signals for
-- the rest of the components.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

entity instruction_decoder is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Wait for read data
          I_waitfordata : in std_logic;
          -- Should we branch?
          I_branch : in std_logic;
          -- Interrupt request + type
          I_interrupt_request : in interrupt_request_type;
          -- The instruction
          I_instr : in data_type;
          -- Alu operation
          O_alu_op : out alu_op_type;
          -- Destination register
          O_rd : out reg_type;
          -- Enable destination register
          O_rd_enable : out std_logic;
          -- Select bits of registers
          O_rs1 : out reg_type;
          O_rs2 : out reg_type;
          -- Shift amount
          O_shift : out shift_type;
          -- Immediate value
          O_immediate : out data_type;
          -- Access size on memory
          O_size : out size_type;
          -- Offset for load/store/jump/branch
          O_offset : out data_type; 
          -- PC operation
          O_pc_op : out pc_op_type;
          -- Type of memory access
          O_memaccess : out memaccess_type;
          -- CSR operation
          O_csr_op : out csr_op_type;
          O_csr_immrs1 : out csrimmrs1_type;
          O_csr_addr : out csraddr_type;
          O_csr_instret : out std_logic;
          -- Multiply/divide start, ready, operation
          O_md_start : out std_logic;
          I_md_ready : in std_logic;
          O_md_op : out std_logic_vector(2 downto 0);
          -- ECALL/EBREAK/MRET request
          O_ecall_request : out std_logic;
          O_ebreak_request : out std_logic;
          O_mret_request : out std_logic;
          -- Should we restart the instruction
          O_restart_instruction : out std_logic;
          -- Illegal instruction
          O_illegal_instruction_error : out std_logic
         );
end entity instruction_decoder;

architecture rtl of instruction_decoder is
-- Some aliases for easy handling
alias opcode : opcode_type is I_instr(6 downto 0);
alias func3 : func3_type is I_instr(14 downto 12);
alias func7 : func7_type is I_instr(31 downto 25);
alias rd_i : reg_type is I_instr(11 downto 7);
alias rs1_i : reg_type is I_instr(19 downto 15);
alias rs2_i : reg_type is I_instr(24 downto 20);
alias shamt : shift_type is I_instr(24 downto 20);
-- States for the state machine (FSM)
type state_type is (state_unknown,
                    state_fetch,
                    state_fexecute,
                    state_wait,
                    state_md,
                    state_intr);
signal state : state_type;
-- Do we have a penalty? (for jumps, branches taken)
signal penalty : std_logic;
-- Do we start a multiply/divide?
signal start : std_logic;
-- The previous instruction et al.
signal instrprev : data_type;
alias opcodeprev : opcode_type is instrprev(6 downto 0);
alias func3prev : func3_type is instrprev(14 downto 12);
alias rd_iprev : reg_type is instrprev(11 downto 7);
alias rs1_iprev : reg_type is instrprev(19 downto 15);
alias rs2_iprev : reg_type is instrprev(24 downto 20);
begin

    -- The Instruction Decoder state machine (FSM)
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            state <= state_fetch;
            -- NOP as default
            instrprev <= x"00000013";
        elsif rising_edge(I_clk) then
            case state is
                -- Just fetch instruction
                when state_fetch =>
                    instrprev <= I_instr;
                    if I_interrupt_request = irq_hard or I_interrupt_request = irq_soft or I_interrupt_request = irq_hard_soft then
                        state <= state_intr;
                    else
                        state <= state_fexecute;
                    end if;
                -- Execute the instruction
                when state_fexecute =>
                    instrprev <= I_instr;
                    if I_interrupt_request = irq_hard or I_interrupt_request = irq_soft or I_interrupt_request = irq_hard_soft then
                        state <= state_intr;
                    elsif I_waitfordata = '1' then
                        state <= state_wait;
                    elsif penalty = '1' then
                        state <= state_fetch;
                    elsif start = '1' then
                        state <= state_md;
                    else
                        state <= state_fexecute;
                    end if;
                -- Wait for load to complete
                when state_wait =>
                    state <= state_fexecute;
                    if I_interrupt_request = irq_hard or I_interrupt_request = irq_soft or I_interrupt_request = irq_hard_soft then
                        state <= state_intr;
                    else
                        instrprev <= I_instr;
                    end if;
                -- Wait for mul/div/rem to complete
                when state_md =>
                    if I_interrupt_request = irq_hard or I_interrupt_request = irq_soft or I_interrupt_request = irq_hard_soft then
                        state <= state_intr;
                    elsif I_md_ready = '1' then
                        state <= state_fexecute;
                    end if;
                when state_intr =>
                    state <= state_fetch;

                -- If something is horribly wrong, go fetch
                -- new instruction, needs penalty
                when others =>
                    state <= state_fetch;
                    instrprev <= I_instr;
            end case;
        end if;
    end process;
    
    -- Signal that we have to restart the instruction
    process (state, I_waitfordata, start, I_md_ready, penalty, I_interrupt_request) is
    begin
        if state = state_fexecute and I_waitfordata = '1' then
            O_restart_instruction <= '1';
        elsif state = state_fexecute and start = '1' then
            O_restart_instruction <= '1';
        elsif state = state_md and I_md_ready = '0' then
            O_restart_instruction <= '1';
        elsif penalty = '1' then
            O_restart_instruction <= '1';
        elsif I_interrupt_request = irq_hard_soft then
            O_restart_instruction <= '1';
        else
            O_restart_instruction <= '0';
        end if;
    end process;
    
    -- Update the retired instruction counter
    process (state, I_waitfordata, start, I_md_ready) is
    begin
        O_csr_instret <= '0';
        if state = state_md then
            O_csr_instret <= '0';
        elsif state = state_fexecute and I_waitfordata = '0' and start = '0' then
            O_csr_instret <= '1';
        elsif state = state_wait then
            O_csr_instret <= '1';
        elsif state = state_md and I_md_ready = '1' then
            O_csr_instret <= '1';
        elsif state = state_intr then
            O_csr_instret <= '0';
        end if;
    end process;

    -- The Instruction Decoder (comb. logic)
    process (state, instrprev, I_instr, I_waitfordata, I_branch, I_md_ready) is
    begin
        -- Set defaults
        O_alu_op <= alu_nop;
        O_rd <= (others => '-');
        O_rd_enable <= '0';
        O_rs1 <= (others => '-');
        O_rs2 <= (others => '-');
        O_shift <= (others => '-');
        O_immediate <= (others => '-');
        O_size <= size_unknown;
        O_offset <= (others => '-');
        O_pc_op <= pc_incr;
        O_memaccess <= memaccess_nop;
        O_csr_op <= csr_nop;
        O_csr_addr <= (others => '-');
        O_csr_immrs1 <= (others => '-');
        O_md_op <= (others => '-');
        O_ecall_request <= '0';
        O_ebreak_request <= '0';
        O_mret_request <= '0';
        O_illegal_instruction_error <= '0';
        penalty <= '0';
        start <= '0';

        case state is
        when state_fetch =>
            -- Just fetch the new instruction
            null;
        when state_fexecute =>
            -- Parse opcodes
            case opcode is
                -- LUI
                when "0110111" =>
                    O_alu_op <= alu_lui;
                    O_rd <= rd_i;
                    O_rd_enable <= '1';
                    O_immediate(31 downto 12) <= I_instr(31 downto 12);
                    O_immediate(11 downto 0) <= (others => '0');
                -- AUIPC
                when "0010111" =>
                    O_alu_op <= alu_auipc;
                    O_rd <= rd_i;
                    O_rd_enable <= '1';
                    O_immediate(31 downto 12) <= I_instr(31 downto 12);
                    O_immediate(11 downto 0) <= (others => '0');
                -- JAL
                when "1101111" =>
                    O_alu_op <= alu_jal;
                    O_pc_op <= pc_loadoffset;
                    O_rd <= rd_i;
                    O_rs1 <= rs1_i;
                    O_rd_enable <= '1';
                    O_offset <= (0 => '0', others => I_instr(31));
                    O_offset(20 downto 1) <= I_instr(31) & I_instr(19 downto 12) & I_instr(20) & I_instr(30 downto 21);
                    O_offset(0) <= '0';
                    penalty <= '1';
                -- JALR
                when "1100111" =>
                    if func3 = "000" then
                        O_alu_op <= alu_jalr;
                        O_pc_op <= pc_loadoffsetregister;
                        O_rd <= rd_i;
                        O_rs1 <= rs1_i;
                        O_rd_enable <= '1';
                        O_offset <= (0 => '0', others => I_instr(31));
                        O_offset(11 downto 0) <= I_instr(31 downto 20);
                        penalty <= '1';
                    else
                        O_illegal_instruction_error <= '1';
                    end if;
                -- Branches
                when "1100011" =>
                    -- Set the registers to compare. Comparison is handled by the ALU.
                    O_rs1 <= rs1_i;
                    O_rs2 <= rs2_i;
                    O_offset <= (0 => '0', others => I_instr(31));
                    O_offset(12 downto 1) <= I_instr(31) & I_instr(7) & I_instr(30 downto 25) & I_instr(11 downto 8);
                    O_pc_op <= pc_branch;
                    if I_branch = '1' then
                        penalty <= '1';
                    end if;
                    case func3 is
                        when "000" => O_alu_op <= alu_beq;
                        when "001" => O_alu_op <= alu_bne;
                        when "100" => O_alu_op <= alu_blt;
                        when "101" => O_alu_op <= alu_bge;
                        when "110" => O_alu_op <= alu_bltu;
                        when "111" => O_alu_op <= alu_bgeu;
                        when others =>
                            -- Reset defaults
                            O_rs1 <= (others => '-');
                            O_rs2 <= (others => '-');
                            O_offset <= (others => '-');
                            O_pc_op <= pc_incr;
                            O_illegal_instruction_error <= '1';
                            penalty <= '0';
                    end case;
                -- L{W|H|B|HU|BU}
                when "0000011" =>
                    case func3 is
                        -- LB
                        when "000" =>
                            O_alu_op <= alu_lb;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_byte;
                            O_rs1 <= rs1_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 20);
                            -- If we get a signal back that we should wait
                            -- for the data to be available, halt the PC
                            -- and disable the ALU and writeback.
                            if I_waitfordata = '1' then
                                O_pc_op <= pc_hold;
                                O_alu_op <= alu_nop;
                                O_rd <= (others => '-');
                                O_rd_enable <= '0';
                            end if;
                        -- LH
                        when "001" =>
                            O_alu_op <= alu_lh;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_halfword;
                            O_rs1 <= rs1_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 20);
                            -- If we get a signal back that we should wait
                            -- for the data to be available, halt the PC
                            -- and disable the ALU and writeback.
                            if I_waitfordata = '1' then
                                O_pc_op <= pc_hold;
                                O_alu_op <= alu_nop;
                                O_rd <= (others => '-');
                                O_rd_enable <= '0';
                            end if;
                        -- LW
                        when "010" =>
                            O_alu_op <= alu_lw;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_word;
                            O_rs1 <= rs1_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 20);
                            -- If we get a signal back that we should wait
                            -- for the data to be available, halt the PC
                            -- and disable the ALU and writeback.
                            if I_waitfordata = '1' then
                                O_pc_op <= pc_hold;
                                O_alu_op <= alu_nop;
                                O_rd <= (others => '-');
                                O_rd_enable <= '0';
                            end if;
                        -- LBU
                        when "100" =>
                            O_alu_op <= alu_lbu;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_byte;
                            O_rs1 <= rs1_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 20);
                            -- If we get a signal back that we should wait
                            -- for the data to be available, halt the PC
                            -- and disable the ALU and writeback.
                            if I_waitfordata = '1' then
                                O_pc_op <= pc_hold;
                                O_alu_op <= alu_nop;
                                O_rd <= (others => '-');
                                O_rd_enable <= '0';
                            end if;
                        -- LHU
                        when "101" =>
                            O_alu_op <= alu_lhu;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_halfword;
                            O_rs1 <= rs1_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 20);
                            -- If we get a signal back that we should wait
                            -- for the data to be available, halt the PC
                            -- and disable the ALU and writeback.
                            if I_waitfordata = '1' then
                                O_pc_op <= pc_hold;
                                O_alu_op <= alu_nop;
                                O_rd <= (others => '-');
                                O_rd_enable <= '0';
                            end if;
                        when others =>
                            O_illegal_instruction_error <= '1';
                    end case;
                -- S(W|H|B)
                when "0100011" =>
                    case func3 is
                        -- Store byte (no sign extension of zero extension)
                        when "000" =>
                            O_alu_op <= alu_nop;
                            O_memaccess <= memaccess_write;
                            O_size <= size_byte;
                            O_rs1 <= rs1_i;
                            O_rs2 <= rs2_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 25) & I_instr(11 downto 7);
                        -- Store halfword (no sign extension of zero extension)
                        when "001" =>
                            O_alu_op <= alu_nop;
                            O_memaccess <= memaccess_write;
                            O_size <= size_halfword;
                            O_rs1 <= rs1_i;
                            O_rs2 <= rs2_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 25) & I_instr(11 downto 7);
                        -- Store word
                        when "010" =>
                            O_alu_op <= alu_nop;
                            O_memaccess <= memaccess_write;
                            O_size <= size_word;
                            O_rs1 <= rs1_i;
                            O_rs2 <= rs2_i;
                            O_offset <= (others => I_instr(31));
                            O_offset(11 downto 0) <= I_instr(31 downto 25) & I_instr(11 downto 7);
                        when others =>
                            O_illegal_instruction_error <= '1';
                    end case;
                -- Arithmetic/logic register/immediate
                when "0010011" =>
                    -- ADDI
                    if func3 = "000" then
                        O_alu_op <= alu_addi;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => I_instr(31));
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- SLTI
                    elsif func3 = "010" then
                        O_alu_op <= alu_slti;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => I_instr(31));
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- SLTIU
                    elsif func3 = "011" then
                        O_alu_op <= alu_sltiu;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => '0');
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- XORI
                    elsif func3 = "100" then
                        O_alu_op <= alu_xori;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => I_instr(31));
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- ORI
                    elsif func3 = "110" then
                        O_alu_op <= alu_ori;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => I_instr(31));
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- ANDI
                    elsif func3 = "111" then
                        O_alu_op <= alu_andi;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_immediate <= (others => I_instr(31));
                        O_immediate(11 downto 0) <= I_instr(31 downto 20);
                    -- SLLI
                    elsif func3 = "001" and func7 = "0000000" then
                        O_alu_op <= alu_slli;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_shift <= shamt;
                        O_rs1 <= rs1_i;
                        O_rd <= rd_i;
                    -- SRLI
                    elsif func3 = "101" and func7 = "0000000" then
                        O_alu_op <= alu_srli;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_shift <= shamt;
                        O_rs1 <= rs1_i;
                        O_rd <= rd_i;
                    -- SRAI
                    elsif func3 = "101" and func7 = "0100000" then
                        O_alu_op <= alu_srai;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_shift <= shamt;
                        O_rs1 <= rs1_i;
                        O_rd <= rd_i;
                    else
                        O_illegal_instruction_error <= '1';
                    end if;
                    
                -- Arithmetic/logic register/register
                when "0110011" =>
                    -- ADD
                    if func3 = "000" and func7 = "0000000" then
                        O_alu_op <= alu_add;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SUB
                    elsif func3 = "000" and func7 = "0100000" then
                        O_alu_op <= alu_sub;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SLL
                    elsif func3 = "001" and func7 = "0000000" then
                        O_alu_op <= alu_sll; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SLT
                    elsif func3 = "010" and func7 = "0000000" then
                        O_alu_op <= alu_slt; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SLTU
                    elsif func3 = "011" and func7 = "0000000" then
                        O_alu_op <= alu_sltu; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- XOR
                    elsif func3 = "100" and func7 = "0000000" then
                        O_alu_op <= alu_xor; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SRL
                    elsif func3 = "101" and func7 = "0000000" then
                        O_alu_op <= alu_srl; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- SRA
                    elsif func3 = "101" and func7 = "0100000" then
                        O_alu_op <= alu_sra; 
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- OR
                    elsif func3 = "110" and func7 = "0000000" then
                        O_alu_op <= alu_or;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- AND
                    elsif func3 = "111" and func7 = "0000000" then
                        O_alu_op <= alu_and;
                        O_rd <= rd_i;
                        O_rd_enable <= '1';
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                    -- Multiply, divide, remainder
                    elsif func7 = "0000001" then
                        O_alu_op <= alu_nop;
                        O_pc_op <= pc_hold;
                        -- func3 contains the function
                        O_md_op <= func3;
                        O_rs1 <= rs1_i;
                        O_rs2 <= rs2_i;
                        -- Start multiply/divide/remainder
                        start <= '1';
                    else
                        O_illegal_instruction_error <= '1';
                    end if;

                -- CSR{}, {ECALL, EBREAK, MRET, WFI}
                when "1110011" =>
                    case func3 is
                        when "000" =>
                            -- ECALL/EBREAK/MRET/WFI
                            if I_instr(31 downto 20) = "000000000000" then
                                -- ECALL
                                O_ecall_request <= '1';
                                O_pc_op <= pc_hold;
                            elsif I_instr(31 downto 20) = "000000000001" then
                                -- EBREAK
                                O_ebreak_request <= '1';
                                O_pc_op <= pc_hold;
                            elsif I_instr(31 downto 20) = "001100000010" then
                                -- MRET
                                O_mret_request <= '1';
                                O_pc_op <= pc_load_mepc;
                                penalty <= '1';
                            elsif I_instr(31 downto 20) = "000100000101" then
                                -- WFI, skip for now
                            else
                                O_illegal_instruction_error <= '1';
                            end if;
                        when "001" =>
                            -- CSRRW
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rw;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- rs1
                        when "010" =>
                            -- CSRRS
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rs;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- rs1
                        when "011" =>
                            -- CSRRC
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rc;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- rs1
                        when "101" =>
                            -- CSRRWI
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rwi;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- imm
                        when "110" =>
                            -- CSRRSI
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rsi;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- imm
                        when "111" =>
                            -- CSRRCI
                            O_alu_op <= alu_csr;
                            O_csr_op <= csr_rci;
                            O_rd <= rd_i;
                            O_rd_enable <= '1';
                            O_rs1 <= rs1_i;
                            O_csr_addr <= I_instr(31 downto 20);
                            O_csr_immrs1 <= rs1_i; -- imm
                        when others =>
                            null;
                    end case;
                    
                -- FENCE (not implemented)
                when "0001111" =>
                    if func3 = "000" then
                        null;
                    else
                        O_illegal_instruction_error <= '1';
                    end if;

                when others =>
                    O_illegal_instruction_error <= '1';
            end case;
            
        when state_wait =>
            -- We have to wait for the data to be read from ROM or RAM
            -- This takes an extra clock cycle so we have to supply the
            -- other building block with the current instruction, but
            -- the PC is already pointing to the next one.
            -- L{W|H|B|HU|BU}
            case opcodeprev is
                when "0000011" =>
                    case func3prev is
                        -- LB
                        when "000" =>
                            O_alu_op <= alu_lb;
                            O_rd <= rd_iprev;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_byte;
                            O_rs1 <= rs1_iprev;
                            O_offset <= (others => instrprev(31));
                            O_offset(11 downto 0) <= instrprev(31 downto 20);
                        -- LH
                        when "001" =>
                            O_alu_op <= alu_lh;
                            O_rd <= rd_iprev;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_halfword;
                            O_rs1 <= rs1_iprev;
                            O_offset <= (others => instrprev(31));
                            O_offset(11 downto 0) <= instrprev(31 downto 20);
                        -- LW
                        when "010" =>
                            O_alu_op <= alu_lw;
                            O_rd <= rd_iprev;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_word;
                            O_rs1 <= rs1_iprev;
                            O_offset <= (others => instrprev(31));
                            O_offset(11 downto 0) <= instrprev(31 downto 20);
                        -- LBU
                        when "100" =>
                            O_alu_op <= alu_lbu;
                            O_rd <= rd_iprev;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_byte;
                            O_rs1 <= rs1_iprev;
                            O_offset <= (others => instrprev(31));
                            O_offset(11 downto 0) <= instrprev(31 downto 20);
                        -- LHU
                        when "101" =>
                            O_alu_op <= alu_lhu;
                            O_rd <= rd_iprev;
                            O_rd_enable <= '1';
                            O_memaccess <= memaccess_read;
                            O_size <= size_halfword;
                            O_rs1 <= rs1_iprev;
                            O_offset <= (others => instrprev(31));
                            O_offset(11 downto 0) <= instrprev(31 downto 20);
                        when others =>
                            O_illegal_instruction_error <= '1';
                    end case;
                -- Should not happen!
                when others =>
                    O_illegal_instruction_error <= '1';
            end case;
        -- We have to wait for multiply/divide to complete
        when state_md =>
            O_alu_op <= alu_nop;
            O_pc_op <= pc_hold;
            -- func3 holds the function
            O_md_op <= func3prev;
            if I_md_ready = '1' then
                O_pc_op <= pc_incr;
                O_rd <= rd_iprev;
                O_rd_enable <= '1';
                case func3prev is
                    when "000" => O_alu_op <= alu_mul;
                    when "001" => O_alu_op <= alu_mulh;
                    when "010" => O_alu_op <= alu_mulhsu;
                    when "011" => O_alu_op <= alu_mulhu;
                    when "100" => O_alu_op <= alu_div;
                    when "101" => O_alu_op <= alu_divu;
                    when "110" => O_alu_op <= alu_rem;
                    when "111" => O_alu_op <= alu_remu;
                    when others => null;
                end case;
            end if;

        -- Process interrupts
        when state_intr =>
            O_pc_op <= pc_load_mtvec;
            
        when others =>
            null;
        end case;
    end process;
    
    O_md_start <= start;
end architecture rtl;