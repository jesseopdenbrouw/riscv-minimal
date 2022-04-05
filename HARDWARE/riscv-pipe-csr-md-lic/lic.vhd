--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- lic.vhd - Local interrupt controller

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This is the Local Interrupt Controller. Currently this is
-- an all combinational circuit. The LIC determines the 
-- current interrupt status based on priority. The system
-- timer has the highest priority, followed by hardware I/O
-- interrupts. Then the synchronous exceptions and ECALL/EBREAK
-- have priority. Interrupts will only occur if mstatus.MIE is
-- active.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity lic is
    port (I_clk: in std_logic;
          I_areset : in std_logic;
          -- mstatus.MIE Interrupt Enable bit
          I_mstatus_mie : in std_logic;
          -- Max 16 external/hardware interrupts + System Timer
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
end entity;

architecture rtl of lic is
constant zeros : data_type := (others => '0');
begin
    process (I_clk, I_areset, I_mstatus_mie, I_intrio, I_ecall_request,
             I_ebreak_request, I_illegal_instruction_error_request,
             I_instruction_misaligned_error_request, 
             I_load_access_error_request,
             I_store_access_error_request,
             I_load_misaligned_error_request,
             I_store_misaligned_error_request,
             I_mret_request) is
    variable interrupt_request_int : interrupt_request_type;
    begin
        interrupt_request_int := irq_none;
        O_interrupt_release <= '0';
        O_mcause <= (others => '0');
        
        if I_mstatus_mie = '1' then
            -- Priority as of Table 3.7 of "Volume II: RISC-V Privileged Architectures V20211203"
            -- Hardware interrupts take priority over exceptions, also the RISC-V system timer
            -- Not all exceptions are implemented
            -- External timer interrupt
            if I_intrio(7) = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(7, O_mcause'length));
                O_mcause(31) <= '1';
            -- USART interrupt
            elsif I_intrio(18) = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(18, O_mcause'length));
                O_mcause(31) <= '1';
            -- TIMER1 interrupt
            elsif I_intrio(17) = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(17, O_mcause'length));
                O_mcause(31) <= '1';
            -- For testing only, will be removed/changed
            elsif I_intrio(16) = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(16, O_mcause'length));
                O_mcause(31) <= '1';
            elsif I_illegal_instruction_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(2, O_mcause'length));
            elsif I_instruction_misaligned_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(0, O_mcause'length));
            elsif I_ecall_request = '1' then
                interrupt_request_int := irq_soft;
                O_mcause <= std_logic_vector(to_unsigned(11, O_mcause'length));
            elsif I_ebreak_request = '1' then
                interrupt_request_int := irq_soft;
                O_mcause <= std_logic_vector(to_unsigned(3, O_mcause'length));
            elsif I_load_access_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(5, O_mcause'length));
            elsif I_store_access_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(7, O_mcause'length));
            elsif I_load_misaligned_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(4, O_mcause'length));
            elsif I_store_misaligned_error_request = '1' then
                interrupt_request_int := irq_hard;
                O_mcause <= std_logic_vector(to_unsigned(6, O_mcause'length));
            end if;
        end if;    
        
        -- Check if a hardware interrupt and ECALL/EBREAK occur at the same time
        if interrupt_request_int = irq_hard and (I_ecall_request = '1' or I_ebreak_request = '1') then
            interrupt_request_int := irq_hard_soft;
        end if;
        O_interrupt_request <= interrupt_request_int;
        
        -- Signal interrupt release
        if I_mret_request = '1' then
            O_interrupt_release <= '1';
        end if;
    end process;
      
end architecture rtl;