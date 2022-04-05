--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- riscv.vhd - Top level structural file

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

-- The processor itself
-- The processor incorporates ROM, RAM and IO,
-- has a multiply/divide unit, CSR and a LIC
entity riscv is
    port (clk : in std_logic;
          areset : in std_logic;
          -- I/O
          pina : in data_type;
          pouta : out data_type;
          RxD : in std_logic;
          TxD : out std_logic
         );
end entity riscv;

-- This architecture is strictly structural
architecture struct of riscv is

-- The registers
component regs is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Data to destination register
          I_datain : in data_type;
          -- Selection of destination register
          I_selrd  : in reg_type;
          -- Enable write to destination register
          I_enable : in std_logic;
          -- Selection of register 1 and register 2
          I_sel1out : in reg_type;
          I_sel2out : in reg_type;
          -- Data selected from register 1 and register 2
          O_rs1out : out data_type;
          O_rs2out : out data_type
         );
end component regs;

-- The ALU
component alu is
    port (I_alu_op : in alu_op_type;
          I_dataa : in data_type;
          I_datab : in data_type;
          I_immediate : in data_type;
          I_shift: in shift_type;
          I_pc : in data_type;
          I_memory : in data_type;
          I_csr : in data_type;
          I_mul : in data_type;
          I_div : in data_type;
          O_result : out data_type
         );
end component alu;

-- The instruction decoder
component instruction_decoder is
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
end component instruction_decoder;

-- The Program Counter
component pc is
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
end component pc;

-- The Address Decoder and Data Router
-- Decodes addresses and routes data from/to
-- ROM, RAM and I/O
component address_decoder_and_data_router is
    port (I_rs : in data_type;
          I_offset : in data_type;
          I_romdatain : in data_type;
          I_ramdatain : in data_type;
          I_iodatain : in data_type;
          I_memaccess : in memaccess_type;
          O_dataout : out data_type;
          O_wrram : out std_logic;
          O_wrio : out std_logic;
          O_addressout : out data_type;
          O_waitfordata : out std_logic;
          O_csrom : out std_logic;
          O_csram : out std_logic;
          O_csio : out std_logic;
          O_load_access_error : out std_logic;
          O_store_access_error : out std_logic
         );
end component address_decoder_and_data_router;

-- The ROM, read only, provides instruction and data
component rom is
    port (I_clk : in std_logic;
          I_csrom : in std_logic;
          I_address1 : in data_type;
          I_address2 : in data_type;
          I_size2 : in size_type;
          O_data1 : out data_type;
          O_data2: out data_type;
          O_load_misaligned_error : out std_logic
         );
end component rom;

-- The RAM, read/write, provides data only
component ram is
    port (I_clk : in std_logic;
          I_csram : in std_logic;
          I_address : in data_type;
          I_datain : in data_type;
          I_size : in size_type;
          I_wren : in std_logic;
          O_dataout : out data_type;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end component ram;

-- The I/O
-- Needs system and clock frequency the create
-- a microsecond clock
component io is
    generic (freq_sys : integer := SYSTEM_FREQUENCY;
             freq_count : integer := CLOCK_FREQUENCY
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_csio : in std_logic;
          I_address : in data_type;
          I_size : size_type;
          I_wren : in std_logic;
          I_datain : in data_type;
          O_dataout : out data_type;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic;
          -- Connection with outside world
          I_pina : in data_type;
          O_pouta : out data_type;
          I_RxD : in std_logic;
          O_TxD : out std_logic;
          -- Hardware interrupt request
          O_intrio : out data_type;
          -- TIME and TIMEH
          O_time : out data_type;
          O_timeh : out data_type
         );
end component io;

-- The integer multiply and divide unit
component md is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_start : in std_logic;
          I_op : in std_logic_vector(2 downto 0);
          I_rs1 : in data_type;
          I_rs2 : in data_type;
          O_ready : out std_logic;
          O_mul_rd : out data_type;
          O_div_rd : out data_type
         );
end component md;

-- The Control and Status Registers
component csr is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Common signals for CSR instructions
          I_csr_op : in csr_op_type;
          I_csr_addr : in csraddr_type;
          I_csr_datain : in data_type;
          I_csr_immrs1 : in csrimmrs1_type;
          I_csr_instret : in std_logic;
          O_csr_dataout : out data_type;
          -- Exceptions/interrupts
          I_interrupt_request : in interrupt_request_type;
          I_interrupt_release : in std_logic;
          -- For use in mip
          I_intrio : in data_type;
          -- Global interrupt enable status
          O_mstatus_mie : out std_logic;
          -- mcause reported by LIC
          I_mcause : in data_type;
          -- The trap vector
          O_mtvec : out data_type;
          -- The saved PC (not always what mepc tells us!)
          O_mepc : out data_type;
          -- PC to save in mepc
          I_pc : in data_type;
          -- PC to save. This is the really PC to save, not what mepc tells us!
          I_pc_to_save : in data_type;
          -- Address on address bus
          I_address : in data_type;
          -- TIME and TIMEH
          I_time : in data_type;
          I_timeh : in data_type
         );
end component csr;

-- The local interrupt controller
component lic is
    port (I_clk: in std_logic;
          I_areset : in std_logic;
          -- mstatus.MIE Interrupt Enable bit
          I_mstatus_mie : in std_logic;
          -- Max 16 external/hardware interrupts
          I_intrio : in data_type;
          -- Synchronous exceptions
          I_ecall_request : in std_logic;
          I_ebreak_request : in std_logic;
          I_illegal_instruction_error_request : in std_logic;
          I_instruction_misaligned_error_request : in std_logic;
          I_load_access_error_request : in std_logic;
          I_store_access_error_request : in std_logic;
          I_load_misaligned_error_request : in std_logic;
          I_store_misaligned_error_request : in std_logic;
          -- MRET instruction detected
          I_mret_request : in std_logic;
          -- mcause value to CSR
          O_mcause : out data_type;
          -- Advertise interrupt request
          O_interrupt_request : out interrupt_request_type;
          -- Advertise interrupt release
          O_interrupt_release : out std_logic
         );
end component lic;

-- Internal connection signals
signal areset_int : std_logic;
signal alu_op_int : alu_op_type;
signal shift_int : shift_type;
signal rd_int : reg_type;
signal rd_enable_int : std_logic;
signal rs1_int : reg_type;
signal rs2_int : reg_type;
signal immediate_int : data_type;
signal size_int : size_type;
signal offset_int: data_type;
signal pc_op_int : pc_op_type;
signal pc_int : data_type;
signal pc_to_mepc_int : data_type;
signal memaccess_int : memaccess_type;
signal result_int : data_type;
signal rs1data_int : data_type;
signal rs2data_int : data_type;
signal memory_int : data_type;
signal instr_int : data_type;
signal romdata_int : data_type;
signal ramdata_int : data_type;
signal iodata_int : data_type;
signal wrram_int : std_logic;
signal wrio_int : std_logic;
signal address_int : data_type;
signal waitfordata_int : std_logic;
signal csrom_int : std_logic;
signal csram_int : std_logic;
signal csio_int : std_logic;
signal csr_op_int : csr_op_type;
signal csr_addr_int : csraddr_type;
signal csr_datain_int : data_type;
signal csr_dataout_int : data_type;
signal csr_immrs1_int : csrimmrs1_type;
signal csr_instret_int : std_logic;
signal md_mul_int : data_type;
signal md_div_int : data_type;
signal md_start_int : std_logic;
signal md_ready_int : std_logic;
signal md_op_int : std_logic_vector(2 downto 0);
signal load_misaligned_error_int : std_logic_vector(2 downto 0);
signal store_misaligned_error_int : std_logic_vector(1 downto 0);
signal load_misaligned_error_merge_int : std_logic;
signal store_misaligned_error_merge_int : std_logic;
signal mtvec2mtvec : data_type;
signal mepc2mepc : data_type;
signal ecall_request_int : std_logic;
signal ebreak_request_int : std_logic;
signal illegal_instruction_error_int : std_logic;
signal instruction_misaligned_error_int : std_logic;
signal mcause_int : data_type;
signal interrupt_request_int : interrupt_request_type;
signal interrupt_release_int : std_logic;
signal interrupt_ack_int : std_logic;
signal mret_request_int : std_logic;
signal mstatus_mie_int : std_logic;
signal intrio_int : data_type;
signal load_access_error_int : std_logic;
signal store_access_error_int : std_logic;
-- Should we restart the instruction
signal restart_instruction_int : std_logic;
signal timer_compare_request_int : std_logic;
-- PC to save. This is the real PC to save, not what mepc tells us.
signal pc_to_save_int : data_type;
-- TIME and TIMEH
signal time_int, timeh_int : data_type;

-- Select the architecture of the ALU
-- The default
--for alu0 : alu use entity work.alu(rtl);
-- Optimzed
for alu0 : alu use entity work.alu(optimized_rtl);

-- Select the architecture of the MD unit
-- The default 32+2 clock ticks
--for md0 : md use entity work.md(rtl);
-- Enhanced 16+2 clock ticks
for md0 : md use entity work.md(rtl_div4);

begin

    -- Input push button is active low
    -- TODO: implement a reset synchronizer
    areset_int <= not areset;
    
    -- The registers
    regs0 : regs
    port map (I_clk => clk,
              I_areset => areset_int,
              I_datain => result_int,
              I_selrd => rd_int,
              I_enable => rd_enable_int,
              I_sel1out => rs1_int,
              I_sel2out => rs2_int,
              O_rs1out => rs1data_int,
              O_rs2out => rs2data_int
    );

    -- The ALU
    alu0 : alu
    port map (I_alu_op => alu_op_int,
              I_dataa => rs1data_int,
              I_datab => rs2data_int,
              I_immediate => immediate_int,
              I_shift => shift_int,
              I_pc => pc_int,
              I_memory => memory_int,
              I_csr => csr_dataout_int,
              I_mul => md_mul_int,
              I_div => md_div_int,
              O_result => result_int
             );

    -- The Progam Counter
    pc0 : pc
    port map (I_clk => clk,
              I_areset => areset_int,
              I_pc_op => pc_op_int,
              I_rs => rs1data_int,
              I_offset => offset_int,
              I_branch => result_int(0),
              I_mtvec => mtvec2mtvec,
              I_mepc => mepc2mepc,
              I_restart_instruction => restart_instruction_int,
              O_pc => pc_int,
              O_pc_to_mepc => pc_to_mepc_int,
              O_pc_to_save => pc_to_save_int,
              O_instruction_misaligned_error => instruction_misaligned_error_int
    );

    -- The Instuction Decoder
    instruction_decoder0 : instruction_decoder
    port map (I_clk => clk,
              I_areset => areset_int,
              I_waitfordata => waitfordata_int,
              I_branch => result_int(0),
              I_interrupt_request => interrupt_request_int,
              I_instr => instr_int,
              O_alu_op => alu_op_int,
              O_rd => rd_int,
              O_rd_enable => rd_enable_int,
              O_rs1 => rs1_int,
              O_rs2 => rs2_int,
              O_shift => shift_int,
              O_immediate => immediate_int,
              O_size => size_int,
              O_offset => offset_int, 
              O_pc_op => pc_op_int,
              O_memaccess => memaccess_int,
              O_csr_op => csr_op_int,
              O_csr_immrs1 => csr_immrs1_int,
              O_csr_addr => csr_addr_int,
              O_csr_instret => csr_instret_int,
              O_md_start => md_start_int,
              I_md_ready => md_ready_int,
              O_md_op => md_op_int,
              O_ecall_request => ecall_request_int,
              O_ebreak_request => ebreak_request_int,
              O_mret_request => mret_request_int,
              O_restart_instruction => restart_instruction_int,
              O_illegal_instruction_error => illegal_instruction_error_int
             );

    -- The Address Decoder and Data Router
    addecroute0 : address_decoder_and_data_router
    port map (I_rs => rs1data_int,
              I_offset => offset_int,
              I_romdatain => romdata_int,
              I_ramdatain => ramdata_int,
              I_iodatain => iodata_int,
              I_memaccess => memaccess_int,
              O_dataout => memory_int,
              O_wrram => wrram_int,
              O_wrio => wrio_int,
              O_addressout => address_int,
              O_csrom => csrom_int,
              O_csram => csram_int,
              O_csio => csio_int,
              O_waitfordata => waitfordata_int,
              O_load_access_error => load_access_error_int,
              O_store_access_error => store_access_error_int
    );

    -- The ROM
    rom0 : rom
    port map (I_clk => clk,
              I_csrom => csrom_int,
              I_address1 => pc_int,
              I_address2 => address_int,
              I_size2 => size_int,
              O_data1 => instr_int,
              O_data2 => romdata_int,
              O_load_misaligned_error => load_misaligned_error_int(2)
              -- No store_misaligned_error
    );

    -- The RAM
    ram0 : ram
    port map (I_clk => clk,
              I_csram => csram_int,
              I_address => address_int,
              I_datain => rs2data_int,
              I_size => size_int,
              I_wren => wrram_int,
              O_dataout => ramdata_int,
              O_load_misaligned_error => load_misaligned_error_int(1),
              O_store_misaligned_error => store_misaligned_error_int(1)
    );
   
   -- The I/O, needs system frequency and clock frequency
    io0 : io
    generic map (freq_sys => SYSTEM_FREQUENCY,
                 freq_count => CLOCK_FREQUENCY
                )
    port map (I_clk => clk,
              I_areset => areset_int,
              I_csio => csio_int,
              I_address => address_int,
              I_size => size_int,
              I_wren => wrio_int,
              I_datain => rs2data_int,
              O_dataout => iodata_int,
              O_load_misaligned_error => load_misaligned_error_int(0),
              O_store_misaligned_error => store_misaligned_error_int(0),
              -- Interrupts pending
              O_intrio => intrio_int,
              -- TIME and TIMEH to CSR
              O_time => time_int,
              O_timeh => timeh_int,
              -- connection with outside world
              I_pina => pina,
              O_pouta => pouta,
              I_RxD => RxD,
              O_TxD => TxD
             );

    -- The hardware multiply and divide unit
    md0: md
    port map (I_clk => clk,
              I_areset => areset_int,
              I_start => md_start_int,
              I_op => md_op_int,
              I_rs1 => rs1data_int,
              I_rs2 => rs2data_int,
              O_ready => md_ready_int,
              O_mul_rd => md_mul_int, 
              O_div_rd => md_div_int
             );

    -- The CSR, the CSR uses a separate address space
    csr0: csr
    port map (I_clk => clk,
              I_areset => areset_int,
              I_csr_op => csr_op_int,
              I_csr_addr => csr_addr_int,
              I_csr_datain => rs1data_int,
              I_csr_immrs1 => csr_immrs1_int,
              I_csr_instret => csr_instret_int,
              O_csr_dataout => csr_dataout_int,
              I_interrupt_request => interrupt_request_int,
              I_interrupt_release => interrupt_release_int,
              I_intrio => intrio_int,
              O_mstatus_mie => mstatus_mie_int,
              I_mcause => mcause_int,
              O_mtvec => mtvec2mtvec,
              O_mepc => mepc2mepc,
              I_pc => pc_to_mepc_int,
              I_pc_to_save => pc_to_save_int,
              I_address => address_int,
              I_time => time_int,
              I_timeh => timeh_int
             );

    -- The local interrupt controller
    lic0: lic
    port map (I_clk => clk,
              I_areset => areset_int,
              I_mstatus_mie => mstatus_mie_int,
              I_ecall_request => ecall_request_int,
              I_ebreak_request => ebreak_request_int,
              I_illegal_instruction_error_request => illegal_instruction_error_int,
              I_instruction_misaligned_error_request => instruction_misaligned_error_int,
              I_load_access_error_request => load_access_error_int,
              I_store_access_error_request => store_access_error_int,
              I_load_misaligned_error_request => load_misaligned_error_merge_int,
              I_store_misaligned_error_request => store_misaligned_error_merge_int,
              I_mret_request => mret_request_int,
              I_intrio => intrio_int,
              O_mcause => mcause_int,
              O_interrupt_request => interrupt_request_int,
              O_interrupt_release => interrupt_release_int
             );
    -- Merge all load and store misaligned errors to one signal
    load_misaligned_error_merge_int <= load_misaligned_error_int(2) or load_misaligned_error_int(1) or load_misaligned_error_int(0);
    store_misaligned_error_merge_int <= store_misaligned_error_int(1) or store_misaligned_error_int(0);

end architecture struct;
