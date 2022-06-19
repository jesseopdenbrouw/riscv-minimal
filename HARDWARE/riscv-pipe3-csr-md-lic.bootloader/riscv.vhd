--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- risc.vhd - the structural description of the processor

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the description of a RISC-V RV32IM core,
-- using a three-stage pipeline, includig address decoding unit,
-- RAM, ROM, I/O, CSR and LIC.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity riscv is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pina : in data_type;
          O_pouta : out data_type;
          I_RxD : in std_logic;
          O_TxD : out std_logic
         );
end entity riscv;

architecture rtl of riscv is
component core is
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
end component core;
component address_decode is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- to core
          I_memaccess : in memaccess_type;
          I_address : in data_type;
          O_waitfordata : out std_logic;
          O_dataout : out data_type; 
          -- to memory
          O_wrrom : out std_logic;
          O_wrram : out std_logic;
          O_wrio : out std_logic;
          O_csrom : out std_logic;
          O_csboot : out std_logic;
          O_csram : out std_logic;
          O_csio : out std_logic;
          I_romdatain : in data_type;
          I_bootdatain : in data_type;
          I_ramdatain : in data_type;
          I_iodatain : in data_type;
          O_load_access_error : out std_logic;
          O_store_access_error : out std_logic
         );
end component address_decode;
component instruction_router is
    port (I_pc : in data_type;
          I_instr_rom : in data_type;
          I_instr_boot : in data_type;
          O_instr_out : out data_type
         );
end component instruction_router;
component rom is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_address : in data_type;
          I_csrom : in std_logic;
          I_wren : in std_logic;
          I_size : in size_type;
          I_stall : in std_logic;
          O_instr : out data_type;
          I_datain : in data_type;
          O_data_out : out data_type;
          --
          O_instruction_misaligned_error : out std_logic;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end component rom;
component ram is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_address : in data_type;
          I_csram : in std_logic;
          I_size : in size_type;
          I_wrram : in std_logic;
          I_datain : in data_type;
          O_dataout : out data_type;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end component ram;
component bootloader is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_address : in data_type;
          I_csboot : in std_logic;
          I_size : in size_type;
          I_stall : in std_logic;
          O_instr : out data_type;
          O_data_out : out data_type;
          --
          O_instruction_misaligned_error : out std_logic;
          O_load_misaligned_error : out std_logic
         );
end component bootloader;
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
          -- mie.MTIE external timer interrupt enable
          O_mie_mtie : out std_logic;
          -- mcause reported by LIC
          I_mcause : in data_type;
          -- The trap vector
          O_mtvec : out data_type;
          -- The saved PC (not always what mepc tells us!)
          O_mepc : out data_type;
          -- PC to save in mepc
          I_pc : in data_type;
          -- Address on address bus, for mtval
          I_address : in data_type;
          -- TIME and TIMEH
          I_time : in data_type;
          I_timeh : in data_type
         );
end component csr;
component lic is
    port (I_clk: in std_logic;
          I_areset : in std_logic;
          -- mstatus.MIE Interrupt Enable bit
          I_mstatus_mie : in std_logic;
          -- mie.MTIE external timer interrupt enable
          I_mie_mtie : in std_logic;
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

signal clk_int : std_logic;
signal areset_int : std_logic;
signal dataout_int : data_type;
signal datain_int : data_type;
signal pc_int : data_type;
signal rominstr_int : data_type;
signal instr_int : data_type;
signal stall_int : std_logic;
signal memaccess_int : memaccess_type;
signal size_int : size_type;
signal address_int : data_type;
signal waitfordata_int : std_logic;
signal wrrom_int : std_logic;
signal wrram_int : std_logic;
signal wrio_int : std_logic;
signal csrom_int : std_logic;
signal csram_int : std_logic;
signal csio_int : std_logic;
signal romdatain_int : data_type;
signal ramdatain_int : data_type;
signal iodatain_int : data_type;
signal instret_int : std_logic;
signal csr_core_2_csr : data_type;
signal csr_csr_2_core : data_type;
signal csr_op_int : csr_op_type;
signal csr_addr_int : csraddr_type;
signal csr_immrs1_int : reg_type;
signal time_int : data_type;
signal timeh_int : data_type;

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
signal timer_compare_request_int : std_logic;
signal pc_to_mepc_int : data_type;
signal mie_mtie_int : std_logic;

signal csboot_int : std_logic;
signal bootinstr_int : data_type;
signal bootdatain_int : data_type;

begin

    clk_int <= I_clk;
    areset_int <= not I_areset;
    
    core0: core
    port map (I_clk => clk_int,
              I_areset => areset_int,
              O_pc => pc_int,
              I_instr => instr_int,
              O_stall => stall_int,
              O_memaccess => memaccess_int,
              O_address => address_int,
              O_size => size_int,
              I_waitfordata => waitfordata_int,
              O_dataout => dataout_int,
              I_datain => datain_int,
              O_instret => instret_int,
              O_csr_op => csr_op_int,
              O_csr_addr => csr_addr_int,
              O_csr_immrs1 => csr_immrs1_int,
              O_csr_dataout => csr_core_2_csr,
              I_csr_datain => csr_csr_2_core,
              O_ecall_request => ecall_request_int,
              O_ebreak_request => ebreak_request_int,
              O_mret_request => mret_request_int,
              I_interrupt_request => interrupt_request_int,
              I_mtvec => mtvec2mtvec,
              O_pc_to_mepc => pc_to_mepc_int,
              I_mepc => mepc2mepc,
              O_illegal_instruction_error => illegal_instruction_error_int
             );
    
    address_decode0: address_decode
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_memaccess => memaccess_int,
              I_address => address_int,
              O_waitfordata => waitfordata_int,
              O_dataout => datain_int,
              O_wrrom => wrrom_int,
              O_wrram => wrram_int,
              O_wrio => wrio_int,
              O_csrom => csrom_int,
              O_csboot => csboot_int,
              O_csram => csram_int,
              O_csio => csio_int,
              I_romdatain => romdatain_int,
              I_bootdatain => bootdatain_int,
              I_ramdatain => ramdatain_int,
              I_iodatain => iodatain_int,
              O_load_access_error => load_access_error_int,
              O_store_access_error => store_access_error_int
    );

    gen_instr_route: if HAVE_BOOT_ROM generate
        instr_route0: instruction_router
        port map (I_pc => pc_int,
                  I_instr_rom => rominstr_int,
                  I_instr_boot => bootinstr_int,
                  O_instr_out => instr_int
                 );
    end generate;
    gen_instr_route_not: if not HAVE_BOOT_ROM generate
        instr_int <= rominstr_int;
    end generate;
    
    rom0: rom
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_pc => pc_int,
              I_address => address_int,
              I_csrom => csrom_int,
              I_wren => wrrom_int,
              I_size => size_int,
              I_stall => stall_int,
              O_instr => rominstr_int,
              I_datain => dataout_int,
              O_data_out => romdatain_int,
              O_instruction_misaligned_error => instruction_misaligned_error_int,
              O_load_misaligned_error => load_misaligned_error_int(2),
              O_store_misaligned_error => open
             );

    bootloader0: bootloader
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_pc => pc_int,
              I_address => address_int,
              I_csboot => csboot_int,
              I_size => size_int,
              I_stall => stall_int,
              O_instr => bootinstr_int,
              O_data_out => bootdatain_int,
              --O_instruction_misaligned_error => instruction_misaligned_error_int,
              --O_load_misaligned_error => load_misaligned_error_int(2)
              O_instruction_misaligned_error => open,
              O_load_misaligned_error => open
             );

    ram0: ram
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_address => address_int,
              I_csram => csram_int,
              I_size => size_int,
              I_wrram => wrram_int,
              I_datain => dataout_int,
              O_dataout => ramdatain_int,
              O_load_misaligned_error => load_misaligned_error_int(1),
              O_store_misaligned_error => store_misaligned_error_int(1)
             );

    io0: io
    generic map (freq_sys => SYSTEM_FREQUENCY,
                 freq_count => CLOCK_FREQUENCY)
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_address => address_int,
              I_csio => csio_int,
              I_wren => wrio_int,
              I_size => size_int,
              I_datain => dataout_int,
              O_dataout => iodatain_int,
              O_load_misaligned_error => load_misaligned_error_int(0),
              O_store_misaligned_error => store_misaligned_error_int(0),
              I_pina => I_pina,
              O_pouta => O_pouta,
              I_RxD => I_RxD,
              O_TxD => O_TxD,
              O_intrio => intrio_int,
              O_time => time_int,
              O_timeh => timeh_int
             );

    csr0: csr
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_csr_op => csr_op_int,
              I_csr_addr => csr_addr_int,
              I_csr_immrs1 => csr_immrs1_int,
              I_csr_instret => instret_int,
              I_csr_datain => csr_core_2_csr,
              O_csr_dataout => csr_csr_2_core,
              I_interrupt_request => interrupt_request_int,
              I_interrupt_release => interrupt_release_int,
              I_intrio => intrio_int,
              O_mstatus_mie => mstatus_mie_int,
              O_mie_mtie => mie_mtie_int,
              I_mcause => mcause_int,
              O_mtvec => mtvec2mtvec,
              O_mepc => mepc2mepc,
              I_pc => pc_to_mepc_int,
              I_address => address_int,
              I_time => time_int,
              I_timeh => timeh_int
             );

    -- The local interrupt controller
    lic0: lic
    port map (I_clk => clk_int,
              I_areset => areset_int,
              I_mstatus_mie => mstatus_mie_int,
              I_mie_mtie => mie_mtie_int,
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

end architecture rtl;
