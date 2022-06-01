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
vcom -93 -work work ${prefix}rom.vhd
vcom -93 -work work ${prefix}ram.vhd
vcom -93 -work work ${prefix}io.vhd
vcom -93 -work work ${prefix}csr.vhd
vcom -93 -work work ${prefix}lic.vhd
vcom -93 -work work ${prefix}core.vhd
vcom -93 -work work ${prefix}address_decode.vhd
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
add wave -radix hex -label RxD RxD
add wave -divider "Outputs"
add wave -radix hex -label pouta pouta
add wave -radix hex -label TxD TxD
add wave -radix hex -label O_pc_to_mepc dut/pc_to_mepc_int
add wave            -label select_pc dut/core0/select_pc
add wave -divider "Internals - Control"
add wave            -label state dut/core0/state
add wave            -label penalty dut/core0/penalty
add wave            -label stall dut/core0/stall
add wave            -label flush dut/core0/flush
add wave            -label forwarda dut/core0/forwarda
add wave            -label forwardb dut/core0/forwardb
add wave            -label forwardc dut/core0/forwardc
add wave            -label ecall dut/ecall_request_int
add wave            -label ebreak dut/ebreak_request_int
add wave            -label mret dut/mret_request_int
add wave            -label interrupt_request_int dut/interrupt_request_int
#add wave            -label I_interrupt_request dut/core0/I_interrupt_request
add wave -divider "Internals - Instruction Fetch"
add wave -radix hex -label pc dut/core0/pc
add wave            -label pc_op dut/core0/pc_op
add wave -radix hex -label pc_fetch dut/core0/pc_fetch
add wave -radix hex -label instruction dut/core0/I_instr
add wave -divider "Internals - Instruction Decode"
add wave -radix hex -label pc_decode dut/core0/pc_decode
add wave -radix hex -label instr_decode dut/core0/instr_decode
add wave            -label alu_op dut/core0/alu_op
add wave -radix hex -label rd dut/core0/rd
add wave -radix hex -label rd_en dut/core0/rd_en
add wave -radix hex -label rs1 dut/core0/rs1
add wave -radix hex -label rs2 dut/core0/rs2
add wave -radix hex -label imm dut/core0/imm
add wave -radix hex -label rs1data dut/core0/rs1data
add wave -radix hex -label rs2data dut/core0/rs2data
add wave -divider "Internals - Execute & Retire"
add wave -radix hex -label result dut/core0/result
add wave -radix hex -label regs dut/core0/regs_int
add wave -radix hex -label rd_ex dut/core0/rd_ex
add wave -radix hex -label rd_en_ex dut/core0/rd_en_ex
add wave -radix hex -label rddata_ex dut/core0/rddata_ex
add wave            -label instret dut/core0/O_instret
add wave -divider "Internals - Execute MD"
add wave            -label md_start dut/core0/md_start
add wave            -label md_ready dut/core0/md_ready
add wave            -label mul dut/core0/mul
add wave            -label md_op dut/core0/md_op
add wave            -label rdata_a dut/core0/rdata_a
add wave            -label rdata_b dut/core0/rdata_b
add wave            -label div dut/core0/div
add wave -divider "Internals - Memory"
add wave            -label memaccess dut/memaccess_int
add wave            -label size dut/size_int
add wave            -label address_out dut/address_int
add wave            -label waitfordata dut/waitfordata_int
#add wave            -label csrom dut/csrom_int
add wave -divider "Internals - CSR"
add wave            -label csr_op dut/csr_op_int
add wave            -label csr_addr dut/csr_addr_int
add wave            -label csr_datain dut/csr_core_2_csr
add wave -radix hex -label csr dut/csr0/csr
add wave -radix hex -label mstatus dut/csr0/csr(768)
add wave -radix hex -label mepc dut/csr0/csr(833)
add wave -radix hex -label mcause dut/csr0/csr(834)
#add wave            -label time dut/time_int
add wave -divider "Internals - RAM"
add wave -radix hex -label ram dut/ram0/ram_alt
#add wave -divider "Internals - ROM"
#add wave -radix hex -label rom dut/rom
add wave -divider "Internals - IO"
add wave -radix hex -label io dut/io0/io

# Open Structure, Signals (waveform) and List window
view structure
#view list
view signals

# Disable NUMERIC STD Warnings
# This will speed up simulation considerably
# and prevents writing to the transcript file
set NumericStdNoWarnings 1

# Run simulation for xx us
run 4 us

# Fill up the waveform in the window
wave zoom full