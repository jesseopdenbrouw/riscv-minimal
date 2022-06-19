--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- core.vhd - the processor core

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the description of a RISC-V RV32IM core,
-- using a three-stage pipeline. It contains the PC, the
-- instruction decoder and the ALU, the MD unit and the
-- memory interface unit.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity core is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Instructions from ROM
          O_pc : out data_type;
          I_instr : in data_type;
          O_stall : out std_logic;
          -- To memory
          O_memaccess : out memaccess_type;
          O_size : out size_type;
          O_address : out data_type;
          I_waitfordata : in std_logic;
          O_dataout : out data_type; 
          I_datain : in data_type;
          -- To CSR
          O_instret : out std_logic;
          O_csr_op : out csr_op_type;
          O_csr_addr: out csraddr_type;
          O_csr_immrs1 : out reg_type;
          O_csr_dataout : out data_type;
          I_csr_datain : in data_type;
          -- Trap handling
          O_ecall_request : out std_logic;
          O_ebreak_request : out std_logic;
          O_mret_request : out std_logic;
          I_interrupt_request : in interrupt_request_type;
          I_mtvec : in data_type;
          O_pc_to_mepc : out data_type;
          I_mepc : in data_type;
          --Instruction error
          O_illegal_instruction_error : out std_logic
         );
end entity core;

architecture rtl of core is

-- The Program Counter et al.
signal pc : data_type;
signal pc_fetch : data_type;
signal pc_decode : data_type;
signal pc_ex : data_type;
signal pc_op : pc_op_type;

-- The fetched instruction
signal instr_fetch : data_type;

-- The decoded instructions and all
-- control/data signals to ALU etc.
-- synthesis translate_off
signal instr_decode : data_type;
-- synthesis translate_on
signal rd : reg_type;
signal rd_en : std_logic;
signal rs1 : reg_type;
signal rs2 : reg_type;
signal alu_op : alu_op_type;
signal imm : data_type;
signal md_op : func3_type;
signal md_start : std_logic;
signal rs1data : data_type;
signal rs2data : data_type;
signal memaccess_decode : memaccess_type;
signal size_decode : size_type;
signal csr_op_decode : csr_op_type;

-- The retired data
signal rd_ex : reg_type;
signal rd_en_ex : std_logic;
signal rddata_ex : data_type;

-- The registers
type regs_array_type is array (0 to NUMBER_OF_REGISTERS-1) of data_type;
signal regs_int : regs_array_type;

-- The result from the ALU
signal result : data_type;

-- Data forwarders
signal forwarda : std_logic;
signal forwardb : std_logic;
signal forwardc : std_logic;

-- Control
type state_type is (state_boot0, state_boot1, state_exec, state_wait, state_flush, state_md, state_intr, state_intr2, state_mret, state_mret2);
signal state : state_type;
signal penalty : std_logic;
signal flush : std_logic;
signal stall : std_logic;
signal ecall_request : std_logic;
signal ebreak_request : std_logic;
signal mret_request : std_logic;

-- The signals of the multiplier
signal md_ready : std_logic;
-- The signals of the multiplier
signal rdata_a, rdata_b : unsigned(32 downto 0);
signal mul_rd_int : signed(65 downto 0);
signal mul_running : std_logic;
signal mul_ready : std_logic;
signal mul : data_type;

-- The signals of the divider
signal buf : unsigned(63 downto 0);
-- The divisor, for slow divider
signal divisor : unsigned(31 downto 0);
-- The divisor times 1, 2 and 3, for fast divider
signal divisor1: unsigned(33 downto 0);
signal divisor2: unsigned(33 downto 0);
signal divisor3: unsigned(33 downto 0);
signal quotient : unsigned(31 downto 0);
signal remainder : unsigned(31 downto 0);
-- synthesis translate_off
signal count: integer range 0 to 32;
-- synthesis translate_on
signal outsign : std_logic;
signal div_ready : std_logic;
constant all_zeros : std_logic_vector(31 downto 0) := (others => '0');
alias buf1 is buf(63 downto 32);
alias buf2 is buf(31 downto 0);
signal div : data_type;

-- Determine the correct PC to be loaded into mepc on trap
signal pc_to_mepc : data_type;
signal select_pc : std_logic;

begin
   
   -- Determine which PC value must be loaded into mepc on trap
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            pc_to_mepc <= (others => '0');
        elsif rising_edge(I_clk) then
            if state /= state_flush then
                pc_to_mepc <= pc_decode;
            end if;
        end if;
    end process;
    O_pc_to_mepc <= pc_decode when select_pc = '1' else pc_to_mepc;
    
    --
    -- Control block:
    -- This block holds the current processing state of the
    -- processor and supplies the control signals to the
    -- other block.
    --
    
    -- Processor state control
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            state <= state_boot0;
        elsif rising_edge(I_clk) then
            case state is
                -- Booting first cycle
                when state_boot0 =>
                    state <= state_boot1;
                -- Booting second cycle
                when state_boot1 =>
                    state <= state_exec;
                -- The executing state
                when state_exec =>
                    -- Trap can be hard (IRQ) of soft (ECALL, EBREAK)
                    if I_interrupt_request = irq_hard or I_interrupt_request = irq_soft then
                        state <= state_intr;
                    elsif mret_request = '1' then
                        state <= state_mret;
                    -- If we have a penalty, we have to flush the pipeline for two cycles
                    elsif penalty = '1' then
                        state <= state_flush;
                    -- If we have to wait for data, we need to wait one extra cycle
                    elsif I_waitfordata = '1' then
                        state <= state_wait;
                    -- If the MD unit is started....
                    elsif md_start = '1' then
                        state <= state_md;
                    end if;
                -- Wait for data (read from ROM or RAM)
                when state_wait =>
                    -- During wait for data, trap can only be hard
                    if I_interrupt_request = irq_hard then
                        state <= state_intr;
                    else
                        state <= state_exec;
                    end if;
                -- Flush
                when state_flush =>
                    -- During JAL, JALR, Bxx, trap can only be hard (IRQ)
                    if I_interrupt_request = irq_hard then
                        state <= state_intr;
                    else
                        state <= state_exec;
                    end if;
                -- MD operation in progress
                when state_md =>
                    -- During MD operation, trap can only be hard (IRQ)
                    if I_interrupt_request = irq_hard then
                        state <= state_intr;
                    elsif md_ready = '1' then
                        state <= state_exec;
                    end if;
                -- First state of trap handling, flushes pipeline
                when state_intr =>
                    state <= state_intr2;
                -- Second state of trap handling, flushes pipeline
                when state_intr2 =>
                    state <= state_exec;
                -- First state of MRET, flushes the pipeline
                when state_mret =>
                    state <= state_mret2;
                -- Second state of MRET, flushes the pipeline
                when state_mret2 =>
                    state <= state_exec;
                when others =>
                    state <= state_exec;
            end case;
        end if;
    end process;
    
    -- Determine stall
    -- We need to stall if we are waiting for data from memory OR we stall the PC and md unit is not ready
    stall <= '1' when (state = state_exec and I_waitfordata = '1') or
                      (state = state_md) or
                      (state = state_exec and md_start = '1')
                 else '0';
    -- Needed for the instruction fetch for the ROM
    O_stall <= stall;

    -- We need to flush if we are jumping/branching or servicing interrupts
    flush <= '1' when penalty = '1' or state = state_flush or state = state_intr or state = state_intr2 or
                      state = state_mret or state = state_boot0 else '0'; -- for now

    -- Instructions retired -- not exact, needs more detail
    O_instret <= '1' when (state = state_exec and I_interrupt_request = irq_none and I_waitfordata = '0' and md_start = '0' and penalty = '0') or
                          (state = state_wait and I_interrupt_request = irq_none) else '0'; 
    
    -- Data forwarder. Forward RS1/RS2 if they are used in current instruction,
    -- and were written in the previous instruction.
    process (rd_ex, rs1, rs2, rd_en_ex, forwarda) is
    begin
        if rd_en_ex = '1' and rd_ex = rs1 then
            forwarda <= '1';
        else
            forwarda <= '0';
        end if;
        if rd_en_ex = '1' and rd_ex = rs2 then
            forwardb <= '1';
        else
            forwardb <= '0';
        end if;
        -- Follows forwarda
        forwardc <= forwarda;
    end process;


    --
    -- Instruction fetch block
    -- This block controls the instruction fetch from the ROM.
    -- It also instructs the PC to load a new address, either
    -- the next sequencial address or a jump target address.
    --
    
    -- The PC
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            pc <= (others => '0');
            if HAVE_BOOT_ROM then
                pc(31 downto 28) <= bootloader_high_nibble;
            else
                pc(31 downto 28) <= rom_high_nibble;
            end if;
        elsif rising_edge(I_clk) then
            -- Should we stall the pipeline
            if stall = '1' then
                -- PC holds value
                null;
            else
                case pc_op is
                    -- Hold the PC
                    when pc_hold =>
                        null;
                    -- Increment the PC
                    when pc_incr =>
                        pc <= std_logic_vector(unsigned(pc) + 4);
                    -- JAL
                    when pc_loadoffset =>
                        pc <= std_logic_vector(unsigned(pc_decode) + unsigned(imm));
                    -- JALR
                    when pc_loadoffsetregister =>
                        -- Check forwarding
                        if forwarda = '1' then
                            pc <= std_logic_vector(unsigned(imm) + unsigned(rddata_ex));
                        else
                            pc <= std_logic_vector(unsigned(imm) + unsigned(rs1data));
                        end if;
                    -- Branch
                    when pc_branch =>
                        -- Must we branch?
                        if penalty = '1' then
                            pc <= std_logic_vector(unsigned(pc_decode) + unsigned(imm));
                        else
                            pc <= std_logic_vector(unsigned(pc) + 4);
                        end if;
                    -- Load mtvec but only if we must
                    when pc_load_mtvec =>
                        pc <= I_mtvec;
                    -- Load mepc
                    when pc_load_mepc =>
                        pc <= I_mepc;
                    when others =>
                        pc <= std_logic_vector(unsigned(pc) + 4);
                end case;
            end if;
            -- Lower two bits always 0
            pc(1 downto 0) <= "00";
        end if;
    end process;
    -- For fetching instructions
    O_pc <= pc;
    
    -- The PC at the fetched instruction
    process (I_clk, I_areset) is
    variable instr_var : data_type;
    begin
        if I_areset = '1' then
            -- Set at 0x00000000 because after reset
            -- the processor will run for two booting
            -- states. After that, this PC will follow
            -- the PC.
            pc_fetch <= (others => '0');
        elsif rising_edge(I_clk) then
            -- Must we stall?
            if stall = '1' or pc_op = pc_hold then
                null;
            else
                pc_fetch <= pc;
            end if;
        end if;
    end process;
    
    --
    -- Instruction decode block
    -- This block decodes the instruction
    --
    
    -- Decode the instruction
    process (I_clk, I_areset, I_instr, stall, penalty, flush, state) is
    variable opcode : std_logic_vector(6 downto 0);
    variable func3 : std_logic_vector(2 downto 0);
    variable func7 : std_logic_vector(6 downto 0);
    variable imm_u : data_type;
    variable imm_j : data_type;
    variable imm_i : data_type;
    variable imm_b : data_type;
    variable imm_s : data_type;
    variable imm_shamt : data_type;
    variable rs1_i, rs2_i, rd_i : reg_type;
    variable selaout_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    variable selbout_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    begin

        -- Replace opcode with a nop if we flush
        if flush = '1' then
            opcode := "0010011"; --nop
            rd_i := (others => '0');
        else
            -- Get the opcode
            opcode := I_instr(6 downto 0);
            rd_i := I_instr(11 downto 7);
        end if;

        -- Registers to select
        rs1_i := I_instr(19 downto 15);
        rs2_i := I_instr(24 downto 20);

        -- Get function (extends the opcode)
        func3 := I_instr(14 downto 12);
        func7 := I_instr(31 downto 25);

        -- Create all immediate formats
        imm_u(31 downto 12) := I_instr(31 downto 12);
        imm_u(11 downto 0) := (others => '0');
        
        imm_j(31 downto 21) := (others => I_instr(31));
        imm_j(20 downto 1) := I_instr(31) & I_instr(19 downto 12) & I_instr(20) & I_instr(30 downto 21);
        imm_j(0) := '0';

        imm_i(31 downto 12) := (others => I_instr(31));
        imm_i(11 downto 0) := I_instr(31 downto 20);
        
        imm_b(31 downto 13) := (others => I_instr(31));
        imm_b(12 downto 1) := I_instr(31) & I_instr(7) & I_instr(30 downto 25) & I_instr(11 downto 8);
        imm_b(0) := '0';

        imm_s(31 downto 12) := (others => I_instr(31));
        imm_s(11 downto 0) := I_instr(31 downto 25) & I_instr(11 downto 7);
        
        imm_shamt(31 downto 5) := (others => '0');
        imm_shamt(4 downto 0) := rs2_i;

        selaout_int := to_integer(unsigned(rs1_i));
        selbout_int := to_integer(unsigned(rs2_i));
        
        if I_areset = '1' then
            pc_decode <= (others => '0');
            -- synthesis translate_off
            instr_decode <= x"00000013"; -- 0x00000013 == NOP
            -- synthesis translate_on
            rd <= (others => '0');
            rs1 <= (others => '0');
            rs2 <= (others => '0');
            rd_en <= '0';
            imm <= (others => '0');
            alu_op <= alu_unknown;
            pc_op <= pc_incr;
            rs1data <= (others => '0');
            rs2data <= (others => '0');
            md_start <= '0';
            md_op <= (others => '0');
            memaccess_decode <= memaccess_nop;
            size_decode <= size_unknown;
            csr_op_decode <= csr_nop;
            O_csr_addr <= (others => '0');
            O_csr_immrs1 <= (others => '0');
            ecall_request <= '0';
            ebreak_request <= '0';
            mret_request <= '0';
            O_illegal_instruction_error <= '0';
        elsif rising_edge(I_clk) then
            -- If there is a trap request ...
            if I_interrupt_request /= irq_none then
                alu_op <= alu_nop;
                rd <= (others => '0');
                rd_en <= '0';
                pc_op <= pc_load_mtvec;
                ecall_request <= '0';
                ebreak_request <= '0';
            -- We need to stall the operation
            elsif stall = '1' then
                -- Set md_start to 0. It is already registered.
                md_start <= '0';
                -- If the MD unit is ready and we are still doing MD operation,
                -- load the data in the selected register. MD operation can be
                -- interrupted by an interrupt.
                if md_ready = '1' then
                    pc_op <= pc_incr;
                    rd_en <= '1';
                end if;
            else
                pc_decode <= pc_fetch;
                -- synthesis translate_off
                if flush = '1' or state = state_boot0 or state = state_intr or state = state_intr2 then
                    instr_decode <= x"00000013";
                else
                    instr_decode <= I_instr;
                end if;
                -- synthesis translate_on
                rd <= rd_i;
                rs1 <= rs1_i;
                rs2 <= rs2_i;
                rd_en <= '0';
                imm <= (others => '0');
                alu_op <= alu_nop;
                pc_op <= pc_incr;
                rs1data <= regs_int(selaout_int);
                rs2data <= regs_int(selbout_int);
                md_start <= '0';
                md_op <= (others => '0');
                memaccess_decode <= memaccess_nop;
                size_decode <= size_unknown;
                csr_op_decode <= csr_nop;
                O_csr_addr <= (others => '0');
                O_csr_immrs1 <= (others => '0');
                ecall_request <= '0';
                ebreak_request <= '0';
                mret_request <= '0';
                O_illegal_instruction_error <= '0';
                
                if flush = '1' then
                    --alu_op <= alu_flush;
                    alu_op <= alu_nop;
                else
                    case opcode is
                        -- LUI
                        when "0110111" =>
                            alu_op <= alu_lui;
                            rd_en <= '1';
                            imm <= imm_u;
                        -- AUIPC
                        when "0010111" =>
                            alu_op <= alu_auipc;
                            rd_en <= '1';
                            imm <= imm_u;
                        -- JAL
                        when "1101111" =>
                            alu_op <= alu_jal;
                            pc_op <= pc_loadoffset;
                            rd_en <= '1';
                            imm <= imm_j;
                        -- JALR
                        when "1100111" =>
                            if func3 = "000" then
                                alu_op <= alu_jalr;
                                pc_op <= pc_loadoffsetregister;
                                rd_en <= '1';
                                imm <= imm_i;
                            else
                                O_illegal_instruction_error <= '1';
                            end if;
                        -- Branches
                        when "1100011" =>
                            -- Set the registers to compare. Comparison is handled by the ALU.
                            imm <= imm_b;
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
                                    pc_op <= pc_incr;
                                    O_illegal_instruction_error <= '1';
                            end case;

                        -- Arithmetic/logic register/immediate
                        when "0010011" =>
                            -- ADDI
                            if func3 = "000" then
                                alu_op <= alu_addi;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- SLTI
                            elsif func3 = "010" then
                                alu_op <= alu_slti;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- SLTIU
                            elsif func3 = "011" then
                                alu_op <= alu_sltiu;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- XORI
                            elsif func3 = "100" then
                                alu_op <= alu_xori;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- ORI
                            elsif func3 = "110" then
                                alu_op <= alu_ori;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- ANDI
                            elsif func3 = "111" then
                                alu_op <= alu_andi;
                                rd_en <= '1';
                                imm <= imm_i;
                            -- SLLI
                            elsif func3 = "001" and func7 = "0000000" then
                                alu_op <= alu_slli;
                                rd_en <= '1';
                                imm <= imm_shamt;
                            -- SRLI
                            elsif func3 = "101" and func7 = "0000000" then
                                alu_op <= alu_srli;
                                rd_en <= '1';
                                imm <= imm_shamt;
                            -- SRAI
                            elsif func3 = "101" and func7 = "0100000" then
                                alu_op <= alu_srai;
                                rd_en <= '1';
                                imm <= imm_shamt;
                            else
                                O_illegal_instruction_error <= '1';
                            end if;

                        -- Arithmetic/logic register/register
                        when "0110011" =>
                            -- ADD
                            if func3 = "000" and func7 = "0000000" then
                                alu_op <= alu_add;
                                rd_en <= '1';
                            -- SUB
                            elsif func3 = "000" and func7 = "0100000" then
                                alu_op <= alu_sub;
                                rd_en <= '1';
                            -- SLL
                            elsif func3 = "001" and func7 = "0000000" then
                                alu_op <= alu_sll; 
                                rd_en <= '1';
                            -- SLT
                            elsif func3 = "010" and func7 = "0000000" then
                                alu_op <= alu_slt; 
                                rd_en <= '1';
                            -- SLTU
                            elsif func3 = "011" and func7 = "0000000" then
                                alu_op <= alu_sltu; 
                                rd_en <= '1';
                            -- XOR
                            elsif func3 = "100" and func7 = "0000000" then
                                alu_op <= alu_xor; 
                                rd_en <= '1';
                            -- SRL
                            elsif func3 = "101" and func7 = "0000000" then
                                alu_op <= alu_srl; 
                                rd_en <= '1';
                            -- SRA
                            elsif func3 = "101" and func7 = "0100000" then
                                alu_op <= alu_sra; 
                                rd_en <= '1';
                            -- OR
                            elsif func3 = "110" and func7 = "0000000" then
                                alu_op <= alu_or;
                                rd_en <= '1';
                            -- AND
                            elsif func3 = "111" and func7 = "0000000" then
                                alu_op <= alu_and;
                                rd_en <= '1';
                            -- Multiply, divide, remainder
                            elsif func7 = "0000001" then
                                -- Set operation to multiply or divide/remainder
                                -- func3 contains the real operation
                                case func3(2) is
                                    when '0' => alu_op <= alu_multiply;
                                    when '1' => alu_op <= alu_divrem;
                                    when others => null;
                                end case;
                                -- Hold the PC
                                pc_op <= pc_hold;
                                -- func3 contains the function
                                md_op <= func3;
                                -- Start multiply/divide/remainder
                                md_start <= '1';
                            else
                                O_illegal_instruction_error <= '1';
                            end if;

                        -- S(W|H|B)
                        when "0100011" =>
                            case func3 is
                                -- Store byte (no sign extension or zero extension)
                                when "000" =>
                                    alu_op <= alu_sb;
                                    memaccess_decode <= memaccess_write;
                                    size_decode <= size_byte;
                                    imm <= imm_s;
                                -- Store halfword (no sign extension or zero extension)
                                when "001" =>
                                    alu_op <= alu_sh;
                                    memaccess_decode <= memaccess_write;
                                    size_decode <= size_halfword;
                                    imm <= imm_s;
                                -- Store word (no sign extension or zero extension)
                                when "010" =>
                                    alu_op <= alu_sw;
                                    memaccess_decode <= memaccess_write;
                                    size_decode <= size_word;
                                    imm <= imm_s;
                                when others =>
                                    O_illegal_instruction_error <= '1';
                            end case;
                        -- L{W|H|B|HU|BU}
                        -- Data from memory is routed through the ALU
                        when "0000011" =>
                            case func3 is
                                -- LB
                                when "000" =>
                                    alu_op <= alu_lb;
                                    rd_en <= '1';
                                    memaccess_decode <= memaccess_read;
                                    size_decode <= size_byte;
                                    imm <= imm_i;
                                -- LH
                                when "001" =>
                                    alu_op <= alu_lh;
                                    rd_en <= '1';
                                    memaccess_decode <= memaccess_read;
                                    size_decode <= size_halfword;
                                    imm <= imm_i;
                                -- LW
                                when "010" =>
                                    alu_op <= alu_lw;
                                    rd_en <= '1';
                                    memaccess_decode <= memaccess_read;
                                    size_decode <= size_word;
                                    imm <= imm_i;
                                -- LBU
                                when "100" =>
                                    alu_op <= alu_lbu;
                                    rd_en <= '1';
                                    memaccess_decode <= memaccess_read;
                                    size_decode <= size_byte;
                                    imm <= imm_i;
                                -- LHU
                                when "101" =>
                                    alu_op <= alu_lhu;
                                    rd_en <= '1';
                                    memaccess_decode <= memaccess_read;
                                    size_decode <= size_halfword;
                                    imm <= imm_i;
                                when others =>
                                     O_illegal_instruction_error <= '1';
                            end case;

                        -- CSR{}, {ECALL, EBREAK, MRET, WFI}
                        when "1110011" =>
                            case func3 is
                                when "000" =>
                                    -- ECALL/EBREAK/MRET/WFI
                                    if I_instr(31 downto 20) = "000000000000" then
                                        -- ECALL
                                        ecall_request <= '1';
                                        alu_op <= alu_trap;
                                        pc_op <= pc_hold;
                                    elsif I_instr(31 downto 20) = "000000000001" then
                                        -- EBREAK
                                        ebreak_request <= '1';
                                        alu_op <= alu_trap;
                                        pc_op <= pc_hold;
                                    elsif I_instr(31 downto 20) = "001100000010" then
                                        -- MRET
                                        alu_op <= alu_mret;
                                        mret_request <= '1';
                                        pc_op <= pc_load_mepc;
                                    elsif I_instr(31 downto 20) = "000100000101" then
                                        -- WFI, skip for now
                                        null;
                                    else
                                        O_illegal_instruction_error <= '1';
                                    end if;
                                when "001" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rw;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- RS1
                                when "010" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rs;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- RS1
                                when "011" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rc;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- RS1
                                when "101" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rwi;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- imm
                                when "110" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rsi;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    rs1 <= rs1_i;
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- imm
                                when "111" =>
                                    alu_op <= alu_csr;
                                    csr_op_decode <= csr_rci;
                                    rd <= rd_i;
                                    rd_en <= '1';
                                    rs1 <= rs1_i;
                                    O_csr_addr <= imm_i(11 downto 0);
                                    O_csr_immrs1 <= rs1_i; -- imm
                                when others =>
                                    O_illegal_instruction_error <= '1';
                            end case;
                            
                        -- Illegal instruction or not implemented
                        when others =>
                            O_illegal_instruction_error <= '1';
                    end case;
                    
                    -- Do not write if rd is x0 on compute instructions, CSR.
                    -- LUI AUIPC JAL JALR FENCE (they all have xxxx111 as opcode)
                    if (opcode = "0010011" or opcode = "0110011" or opcode(2 downto 0) = "111" or
                        opcode = "0111011" or opcode = "1110011") and rd_i = "00000" then
                        rd_en <= '0';
                    end if;
                end if; -- flush
            end if; -- stall
        end if; -- rising_edge
            
    end process;

    --
    -- The execute block
    -- Contains the ALU, the MD unit and result retire unit
    --
    
    -- ALU
    process (alu_op, rs1data, rs2data, imm, pc, forwarda, forwardb,
             pc_decode, rddata_ex, I_datain, mul,
             div, I_csr_datain, I_interrupt_request) is
    variable a, b, r : unsigned(31 downto 0);
    variable as, bs, ims : signed(31 downto 0);
    variable shamt : integer range 0 to 31;
    variable signs : unsigned(31 downto 0);
    constant zeros : unsigned(31 downto 0) := (others => '0');
    begin
    
        -- Check if forwarding result is needed
        if forwarda = '1' then
            a := unsigned(rddata_ex);
        else
            a := unsigned(rs1data);
        end if;
            
        if forwardb = '1' then
            b := unsigned(rddata_ex);
        else
            b := unsigned(rs2data);
        end if;
        
        r := (others => '0');
        as := signed(a);
        bs := signed(b);
        ims := signed(imm);
        
        penalty <= '0';
        select_pc <= '0';
        
        case alu_op is
            -- No operation
            when alu_nop =>
                null;
            when alu_sw | alu_sh | alu_sb | alu_trap =>
                select_pc <= '1';
            when alu_mret =>
                penalty <= '1';
                
            when alu_add | alu_addi | alu_sub =>
                if alu_op = alu_addi then
                    b := unsigned(imm);
                elsif alu_op = alu_sub then
                    -- Do the two's complement trick
                    b := not(b) + 1;
                end if;
                r := a + b;
                select_pc <= '1';
            when alu_and | alu_andi =>
                if alu_op = alu_andi then
                    b := unsigned(imm);
                end if;
                r := a and b;
                select_pc <= '1';
            when alu_or | alu_ori =>
                if alu_op = alu_ori then
                    b := unsigned(imm);
                end if;
                r := a or b;
                select_pc <= '1';
            when alu_xor | alu_xori =>
                if alu_op = alu_xori then
                    b := unsigned(imm);
                end if;
                r := a xor b;
                select_pc <= '1';
                
            -- Test register & immediate signed/unsigned
            when alu_slti =>
                r := (others => '0');
                if as < ims then
                    r(0) := '1';
                end if;
                select_pc <= '1';
            when alu_sltiu =>
                r := (others => '0');
                if a < unsigned(imm) then
                    r(0) := '1';
                end if;
                select_pc <= '1';
                
            -- Shifts et al
            when alu_sll | alu_slli =>
                if alu_op = alu_slli then
                    b(4 downto 0) := unsigned(imm(4 downto 0));
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
                select_pc <= '1';
            when alu_srl | alu_srli =>
                if alu_op = alu_srli then
                    b(4 downto 0) := unsigned(imm(4 downto 0));
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
                select_pc <= '1';
            when alu_sra | alu_srai =>
                if alu_op = alu_srai then
                    b(4 downto 0) := unsigned(imm(4 downto 0));
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
                select_pc <= '1';
                
            -- Loads etc
            when alu_lui =>
                r := unsigned(imm);
                r(11 downto 0) := (others => '0');
                select_pc <= '1';
            when alu_auipc =>
                r := unsigned(imm);
                r(11 downto 0) := (others => '0');
                r := r + unsigned(pc_decode) ;
                select_pc <= '1';
            when alu_lw =>
                r := unsigned(I_datain);
                select_pc <= '1';
            when alu_lh =>
                r := (others => I_datain(15));
                r(15 downto 0) := unsigned(I_datain(15 downto 0));
                select_pc <= '1';
            when alu_lhu =>
                r := (others => '0');
                r(15 downto 0) := unsigned(I_datain(15 downto 0));
                select_pc <= '1';
            when alu_lb =>
                r := (others => I_datain(7));
                r(7 downto 0) := unsigned(I_datain(7 downto 0));
                select_pc <= '1';
            when alu_lbu =>
                r := (others => '0');
                r(7 downto 0) := unsigned(I_datain(7 downto 0));
                select_pc <= '1';
                
            -- Jumps and calls
            when alu_jal | alu_jalr =>
                r := unsigned(pc_decode)+4;
                penalty <= '1';
                select_pc <= '1';
                
            -- Branches
            when alu_beq =>
                r := (others => '0');
                if a = b then
                    r(0) := '1';
                    penalty <= '1';
                end if;
                select_pc <= '1';
            when alu_bne =>
                r := (others => '0');
                if a /= b then
                    r(0) := '1';
                    penalty <= '1';
                end if;
                select_pc <= '1';
            when alu_blt | alu_slt =>
                r := (others => '0');
                if as < bs then
                    r(0) := '1';
                    if alu_op = alu_blt then
                        penalty <= '1';
                    end if;
                end if;
                select_pc <= '1';
            when alu_bge =>
                r := (others => '0');
                if as >= bs then
                    r(0) := '1';
                    penalty <= '1';
                end if;
                select_pc <= '1';
            when alu_bltu | alu_sltu =>
                r := (others => '0');
                if a < b then
                    r(0) := '1';
                    if alu_op = alu_bltu then
                        penalty <= '1';
                    end if;
                end if;
                select_pc <= '1';
            when alu_bgeu =>
                r := (others => '0');
                if a >= b then
                    r(0) := '1';
                    penalty <= '1';
                end if;
                select_pc <= '1';
                
            -- Pass data from CSR
            when alu_csr =>
                r := unsigned(I_csr_datain);
                select_pc <= '1';
                
            -- Pass data from multiplier
            when alu_multiply =>
                r := unsigned(mul);
                select_pc <= '1';
                
            -- Pass data from divider
            when alu_divrem =>
                r := unsigned(div);
                select_pc <= '1';
                
            when others =>
                r := (others => '0');
        end case;
        
        result <= std_logic_vector(r);
    end process;

    -- The MD unit, can be omitted by setting HAVE_MULDIV to false
    muldivgen: if HAVE_MULDIV generate
        -- Multiplication Unit
        -- Check start of multiplication and load registers
        process (I_clk, I_areset, forwarda, forwardb, rddata_ex, rs1data, rs2data) is
        variable a, b : data_type;
        begin
            -- Check if forwarding result is needed
            if forwarda = '1' then
                a := (rddata_ex);
            else
                a := (rs1data);
            end if;
                
            if forwardb = '1' then
                b := (rddata_ex);
            else
                b := (rs2data);
            end if;
        
            if I_areset = '1' then
                rdata_a <= (others => '0');
                rdata_b <= (others => '0');
                mul_running <= '0';
            elsif rising_edge(I_clk) then
                -- Clock in the multiplicand and multiplier
                -- In the Cyclone V, these are embedded registers
                -- in the DSP units.
                if md_start = '1' then
                    if md_op(1) = '1' then
                        if md_op(0) = '1' then
                            rdata_a <= '0' & unsigned(a);
                        else
                            rdata_a <= a(31) & unsigned(a);
                        end if;
                        rdata_b <= '0' & unsigned(b);
                    else
                        rdata_a <= a(31) & unsigned(a);
                        rdata_b <= b(31) & unsigned(b);
                    end if;
                end if;
                -- Only start when start seen and multiply
                mul_running <= md_start and not md_op(2);
            end if;
        end process;

        -- Do the multiplication
        process(I_clk, I_areset) is
        begin
            if I_areset = '1' then
                mul_rd_int <= (others => '0');
                mul_ready <= '0';
            elsif rising_edge (I_clk) then
                -- Do the multiplication and store in embedded registers
                mul_rd_int <= signed(rdata_a) * signed(rdata_b);
                mul_ready <= mul_running;
            end if;
        end process;
        
        -- Output multiplier result
        process (mul_rd_int, md_op) is
        begin
            if md_op(1) = '1' or md_op(0) = '1' then
                mul <= std_logic_vector(mul_rd_int(63 downto 32));
            else
                mul <= std_logic_vector(mul_rd_int(31 downto 0));
            end if;
        end process;

        fast_div: if FAST_DIVIDE generate
        -- The main divider process. The divider retires 2 bits
        -- at a time, hence 16 cycles are needed. We use a
        -- poor man's radix-4 subtraction unit. It is not the
        -- fastest hardware but the easiest to follow. Consider
        -- a SRT radix-4 divider.
        process (I_clk, I_areset, forwarda, forwardb, rddata_ex, rs1data, rs2data) is
        variable a, b : data_type;
        variable div_running : std_logic;  
        variable count_int : integer range 0 to 32;
        begin 
            -- Check if forwarding result is needed
            if forwarda = '1' then
                a := (rddata_ex);
            else
                a := (rs1data);
            end if;
                
            if forwardb = '1' then
                b := (rddata_ex);
            else
                b := (rs2data);
            end if;

            if I_areset = '1' then
                -- Reset everything
                count_int := 0;
                buf1 <= (others => '0');
                buf2 <= (others => '0');
                divisor1 <= (others => '0');
                divisor2 <= (others => '0');
                divisor3 <= (others => '0');
                div_running := '0';
                div_ready <= '0';
                outsign <= '0';
            elsif rising_edge(I_clk) then 
                -- If start and dividing...
                div_ready <= '0';
                if md_start = '1' and md_op(2) = '1' then
                    -- Signal that we are running
                    div_running := '1';
                    -- For restarting the division
                    count_int := 0;
                end if;
                if div_running = '1' then
                    case count_int is 
                        when 0 =>
                            buf1 <= (others => '0');
                            -- If signed divide, check for negative
                            -- value and make it positive
                            if md_op(0) = '0' and a(31) = '1' then
                                buf2 <= unsigned(not a) + 1;
                            else
                                buf2 <= unsigned(a);
                            end if;
                            -- Load the divisor x1, divisor x2 and divisor x3
                            if md_op(0) = '0' and b(31) = '1' then
                                divisor1 <= "00" & (unsigned(not b) + 1);
                                divisor2 <= ("0" & (unsigned(not b) + 1) & "0");
                                divisor3 <= ("0" & (unsigned(not b) + 1) & "0") + ("00" & (unsigned(not b) + 1));
                            else
                                divisor1 <= ("00" & unsigned(b));
                                divisor2 <= ("0" & unsigned(b) & "0");
                                divisor3 <= ("0" & unsigned(b) & "0") + ("00" & unsigned(b));
                            end if;
                            count_int := count_int + 1;
                            div_ready <= '0';
                            -- Determine the sign of the quotient and remainder
                            if (md_op(0) = '0' and md_op(1) = '0' and (a(31) /= b(31)) and b /= all_zeros) or (md_op(0) = '0' and md_op(1) = '1' and a(31) = '1') then
                                outsign <= '1';
                            else
                                outsign <= '0';
                            end if;
                        when others =>
                            -- Do the divide
                            -- First check is divisor x3 can be subtracted...
                            if buf(63 downto 30) >= divisor3 then
                                buf1(63 downto 32) <= buf(61 downto 30) - divisor3(31 downto 0);
                                buf2 <= buf2(29 downto 0) & "11";
                            -- Then check is divisor x2 can be subtracted...
                            elsif buf(63 downto 30) >= divisor2 then
                                buf1(63 downto 32) <= buf(61 downto 30) - divisor2(31 downto 0);
                                buf2 <= buf2(29 downto 0) & "10";
                            -- Then check is divisor x1 can be subtracted...
                            elsif buf(63 downto 30) >= divisor1 then
                                buf1(63 downto 32) <= buf(61 downto 30) - divisor1(31 downto 0);
                                buf2 <= buf2(29 downto 0) & "01";
                           -- Else no subtraction can be performed.
                            else
                                -- Shift in 0 (00)
                                buf <= buf(61 downto 0) & "00";
                            end if;
                            -- Do this 16 times (32 bit/2 bits at a time, output in last cycle)
                            if count_int /= 16 then
                                count_int := count_int + 1;
                            else
                                -- Ready, show the result
                                count_int := 0;
                                div_running := '0';
                                div_ready <= '1';
                            end if;
                    end case;
                end if;
            end if;
-- synthesis translate_off
            count <= count_int;
-- synthesis translate_on
        end process;
        end generate;
        
        fast_div_not: if not FAST_DIVIDE generate
        -- Division unit, retires one bit at a time
        process (I_clk, I_areset, forwarda, forwardb, rddata_ex, rs1data, rs2data) is
        variable a, b : data_type;
        variable div_running : std_logic;  
        variable count_int : integer range 0 to 32;
        begin
            -- Check if forwarding result is needed
            if forwarda = '1' then
                a := (rddata_ex);
            else
                a := (rs1data);
            end if;
                
            if forwardb = '1' then
                b := (rddata_ex);
            else
                b := (rs2data);
            end if;
            
            if I_areset = '1' then
                -- Reset everything
                count_int := 0;
                buf1 <= (others => '0');
                buf2 <= (others => '0');
                divisor <= (others => '0');
                div_running := '0';
                div_ready <= '0';
                outsign <= '0';
            elsif rising_edge(I_clk) then 
                -- If start and dividing...
                div_ready <= '0';
                if md_start = '1' and md_op(2) = '1' then
                    div_running := '1';
                    count_int := 0;
                end if;
                if div_running = '1' then
                    case count_int is 
                    when 0 => 
                        buf1 <= (others => '0');
                        -- If signed divide, check for negative
                        -- value and make it positive
                        if md_op(0) = '0' and a(31) = '1' then
                            buf2 <= unsigned(not a) + 1;
                        else
                            buf2 <= unsigned(a);
                        end if;
                        if md_op(0) = '0' and b(31) = '1' then
                            divisor <= unsigned(not b) + 1;
                        else
                            divisor <= unsigned(b); 
                        end if;
                        count_int := count_int + 1; 
                        div_ready <= '0';
                        -- Determine the result sign
                        if (md_op(0) = '0' and md_op(1) = '0' and (a(31) /= b(31)) and b /= all_zeros) or (md_op(0) = '0' and md_op(1) = '1' and a(31) = '1') then
                            outsign <= '1';
                        else
                            outsign <= '0';
                        end if;

                    when others =>
                        -- Do the division
                        if buf(62 downto 31) >= divisor then 
                            buf1 <= '0' & (buf(61 downto 31) - divisor(30 downto 0)); 
                            buf2 <= buf2(30 downto 0) & '1'; 
                        else 
                            buf <= buf(62 downto 0) & '0'; 
                        end if;
                        -- Do this 32 times, last one outputs the result
                        if count_int /= 32 then 
                            count_int := count_int + 1;
                        else
                            -- Signal ready
                            count_int := 0;
                            div_running := '0';
                            div_ready <= '1';
                        end if; 
                    end case; 
                end if; 
            end if;
-- synthesis translate_off
            -- Only to view in simulator
            count <= count_int;
-- synthesis translate_on
        end process;
        end generate;
        
        -- Select the correct signedness of the results
        process (outsign, buf2, buf1) is
        begin
            if outsign = '1' then
                quotient <= not buf2 + 1;
                remainder <= not buf1 + 1;
            else
                quotient <= buf2;
                remainder <= buf1; 
            end if;
        end process;

        -- Select the divider output
        div <= std_logic_vector(remainder) when md_op(1) = '1' else std_logic_vector(quotient);
        
        -- Signal that we are ready
        md_ready <= div_ready or mul_ready;
        
    end generate; -- generate MD unit
    
    -- If we don't have an MD unit, set some signals
    -- to default values. The synthesizer will remove the hardware.
    muldivgennot: if not HAVE_MULDIV generate
        md_ready <= '0';
        mul <= (others => '0');
        div <= (others => '0');
    end generate;

    -- Register: exec & retire
    process (I_clk, I_areset, rd) is
    variable selrd_int : integer range 0 to NUMBER_OF_REGISTERS-1;
    begin
        selrd_int := to_integer(unsigned(rd));
        
        if I_areset = '1' then
            regs_int <= (others => (others => '0'));
        elsif rising_edge(I_clk) then
            if stall = '1' then
                null;
            elsif rd_en = '1' and I_interrupt_request = irq_none then
                regs_int(selrd_int) <= result;
            end if;
        end if;
        -- Register 0 is always 0x00000000
        -- Synthesizer with remove this register
        regs_int(0) <= (others => '0');
    end process;

    -- Signal trap related
    O_ecall_request <= ecall_request;
    O_ebreak_request <= ebreak_request;
    O_mret_request <= '1' when state = state_mret2 else '0';

    -- Save a copy of the result for data forwarding
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            rd_ex <= (others => '0');
            rd_en_ex <= '0';
            rddata_ex <= (others => '0');
        elsif rising_edge(I_clk) then
            if stall = '1' then
                null;
            else
                rd_en_ex <= rd_en;
                if rd_en = '1' and I_interrupt_request = irq_none then
                    rddata_ex <= result;
                    rd_ex <= rd;
                end if;
            end if;
        end if;       
    end process;


    --
    -- Memory interface block
    -- Interface to the memory and the CSR
    --

    -- Disable the bus when flushing
    O_memaccess <= memaccess_nop when flush = '1' else memaccess_decode;
    O_size <= size_decode;
    O_csr_op <= csr_nop when flush = '1' else csr_op_decode;
    
    -- This is the interface between the core and the memory (ROM, RAM, I/O)
    -- Memory access type and size are computed in the instruction decoding unit
    process (forwardb, forwardc, rs1data, rs2data, rddata_ex, imm) is
    variable address_var : unsigned(31 downto 0);
    begin
        -- Check if we need forward or not
        if forwardc = '1' then
            address_var := unsigned(rddata_ex);
        else
            address_var := unsigned(rs1data);
        end if;
        address_var := address_var + unsigned(imm);

        -- Data out to memory
        O_address <= std_logic_vector(address_var);
        
        if forwardb = '1' then
            O_dataout <= rddata_ex;
        else
            O_dataout <= rs2data;
        end if;
        
    end process;
    
    -- Set the address of the CSR register
    process (forwarda, rs1data, rddata_ex) is
    begin
        -- Check if we need forward or not
        if forwarda = '1' then
            O_csr_dataout <= rddata_ex;
        else
            O_csr_dataout <= rs1data;
        end if;
       
    end process;
    
end architecture rtl;
