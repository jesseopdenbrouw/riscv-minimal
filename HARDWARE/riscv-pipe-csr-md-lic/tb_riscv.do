#
# This file is part of the RISC-V Minimal Project
#
# (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
#
# tb_riscv.do - Modelsim macro file

# This software is for educational purposes only. 
# This software is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

# Transcript on
transcript on

# Recreate work library
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# Find out if we're started through Quartus or by hand
# (or by using an exec in the Tcl window in Quartus).
# Quartus has the annoying property that it will start
# Modelsim from a directory called "simulation/modelsim".
# The design and the testbench are located in the project
# root, so we've to compensate for that.
if [ string match "*simulation/modelsim" [pwd] ] { 
	set prefix "../../"
	puts "Running Modelsim from Quartus..."
} else {
	set prefix ""
	puts "Running Modelsim..."
}

# Compile the VHDL description and testbench,
# please note that the design and its testbench are located
# in the project root, but the simulator start in directory
# <project_root>/simulation/modelsim, so we have to compensate
# for that.
vcom -93 -work work ${prefix}processor_common.vhd
vcom -93 -work work ${prefix}processor_common_rom.vhd
vcom -93 -work work ${prefix}alu.vhd
vcom -93 -work work ${prefix}regs.vhd
vcom -93 -work work ${prefix}pc.vhd
vcom -93 -work work ${prefix}instruction_decoder.vhd
vcom -93 -work work ${prefix}address_decode.vhd
vcom -93 -work work ${prefix}rom.vhd
vcom -93 -work work ${prefix}rom_inst.vhd
vcom -93 -work work ${prefix}ram.vhd
vcom -93 -work work ${prefix}ram_inst.vhd
vcom -93 -work work ${prefix}io.vhd
vcom -93 -work work ${prefix}csr.vhd
vcom -93 -work work ${prefix}md.vhd
vcom -93 -work work ${prefix}lic.vhd
vcom -93 -work work ${prefix}riscv.vhd
vcom -93 -work work ${prefix}tb_riscv.vhd

# Start the simulator
vsim -t 1ns -L rtl_work -L work -voptargs="+acc" tb_riscv

# Log all signals in the design, good if the number
# of signals is small.
add log -r *

# Add all toplevel signals
# Add a number of signals of the simulated design
add wave -divider "Inputs"
add wave            -label clk clk
add wave            -label areset areset
add wave -radix hex -label pina pina
add wave -divider "Outputs"
add wave -radix hex -label pouta pouta
add wave -divider "Internals"
add wave -divider "PC and instructions"
add wave            -label pc dut/pc_int
add wave            -label pc_prev dut/pc0/pc_prev_int
add wave            -label pc_op dut/pc_op_int
add wave            -label instr dut/instr_int
add wave            -label instrprev dut/instruction_decoder0/instrprev
add wave            -label interrupt_request dut/interrupt_request_int
#add wave            -label timer_compare_request dut/timer_compare_request_int
add wave            -label restart_instruction dut/restart_instruction_int
add wave -divider "FSM Instruction Decoder"
add wave            -label state dut/instruction_decoder0/state
add wave            -label waitfordata dut/waitfordata_int
add wave            -label penalty dut/instruction_decoder0/penalty
add wave            -label start dut/md_start_int
add wave            -label md_ready dut/md_ready_int
add wave            -label interrupt_request dut/interrupt_request_int
add wave            -label csr_instret dut/csr_instret_int
add wave -divider "ALU"
add wave            -label alu_op dut/alu_op_int
add wave            -label shift dut/shift_int
add wave            -label rs1 dut/rs1_int
add wave            -label rs1data dut/rs1data_int
add wave            -label rs2 dut/rs2_int
add wave            -label rs2data dut/rs2data_int
add wave            -label immediate dut/immediate_int
add wave            -label size dut/size_int
add wave            -label offset dut/offset_int
add wave            -label result dut/result_int
add wave            -label rd dut/rd_int
add wave            -label rd_enable dut/rd_enable_int
add wave -divider "Memory"
add wave            -label memory dut/memory_int
add wave            -label address dut/address_int
add wave            -label memaccess dut/memaccess_int
add wave -divider "Chip Selects"
add wave            -label csrom dut/csrom_int
add wave            -label csram dut/csram_int
add wave            -label csio dut/csio_int
add wave -divider "LIC"
add wave            -label ecall_request dut/ecall_request_int
add wave            -label ebreak_request dut/ebreak_request_int
add wave            -label illegal_instruction_error dut/illegal_instruction_error_int
add wave            -label instruction_misaligned_error dut/instruction_misaligned_error_int
add wave            -label load_access_error dut/load_access_error_int
add wave            -label store_access_error dut/store_access_error_int
add wave            -label load_misaligned_error dut/load_misaligned_error_int
add wave            -label store_misaligned_error dut/store_misaligned_error_int
add wave            -label mret_request dut/mret_request_int
add wave            -label intrio dut/intrio_int
add wave            -label interrupt_request dut/interrupt_request_int
add wave            -label interrupt_release dut/interrupt_release_int
add wave            -label mcause dut/mcause_int
add wave -divider "Registers"
add wave            -label regs dut/regs0/regs_int
add wave -divider "ROM"
#add wave            -label rom dut/rom0/rom_inst0/rom
add wave -divider "RAM"
add wave            -label waitfordata dut/waitfordata_int
add wave            -label ram dut/ram0/ram_inst0/ram_int
add wave -divider "I/O"
add wave            -label io dut/io0/io
add wave -divider "CSR"
add wave            -label mstatus dut/csr0/csr(768)
add wave            -label mtvec dut/csr0/csr(773)
add wave            -label mepc dut/csr0/csr(833)
add wave            -label pc_to_save dut/csr0/pc_to_save_int
add wave            -label mcause dut/csr0/csr(834)
add wave            -label instret_32bits dut/csr0/csr(3074)
add wave            -label csr dut/csr0/csr
add wave -divider "MD Unit"
add wave -radix dec -label mul_rd dut/md_mul_int
add wave -radix dec -label div_rd dut/md_div_int
add wave            -label md_op dut/md_op_int
add wave            -label count dut/md0/count
add wave -divider "USART (I/O)"
add wave -radix hex -label txbuffer dut/io0/txbuffer
add wave            -label txstart dut/io0/txstart
add wave            -label txstate dut/io0/txstate
add wave -radix uns -label txbittimer /dut/io0/txbittimer
add wave -radix uns -label txshiftcounter /dut/io0/txshiftcounter
add wave            -label TxD TxD
add wave -radix hex -label rxbuffer dut/io0/rxbuffer
add wave            -label rxstate dut/io0/rxstate
add wave -radix uns -label rxbittimer /dut/io0/rxbittimer
add wave -radix uns -label rxshiftcounter /dut/io0/rxshiftcounter
add wave            -label RxD RxD


# Open Structure, Signals (waveform) and List window
view structure
#view list
view signals

# Disable NUMERIC STD Warnings
# This will speed up simulation considerably
# and prevents writing to the transcript file
set NumericStdNoWarnings 1

# Run simulation for xx us
run 2 us

# Fill up the waveform in the window
wave zoom full