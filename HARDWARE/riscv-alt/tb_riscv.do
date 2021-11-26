#
# This file is part of the RISC-V Minimal Project
#
# (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
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
add wave            -label alu_op_int dut/alu_op_int
add wave            -label shift_int dut/shift_int
add wave            -label rd_int dut/rd_int
add wave            -label rd_enable_int dut/rd_enable_int
add wave            -label rs1_int dut/rs1_int
add wave            -label rs2_int dut/rs2_int
add wave            -label immediate_int dut/immediate_int
add wave            -label size_int dut/size_int
add wave            -label offset_int dut/offset_int;
add wave            -label pc_op_int dut/pc_op_int
add wave            -label pc_int dut/pc_int
add wave            -label memaccess_int dut/memaccess_int
add wave            -label result_int dut/result_int
add wave            -label rs1data_int dut/rs1data_int
add wave            -label rs2data_int dut/rs2data_int
add wave            -label memory_int dut/memory_int
add wave            -label address_int dut/address_int
add wave            -label instr_int dut/instr_int
add wave -divider "FSM"
add wave            -label state dut/instruction_decoder0/state
add wave -divider "Registers"
add wave            -label regs dut/regs0/regs_int
add wave -divider "RAM"
add wave            -label waitfordata dut/waitfordata_int
#add wave -radix hex dut/ram0/*
add wave            -label ram dut/ram0/ram_inst0/ram_int

add wave -divider "I/O"
add wave            -label io dut/io0/io



# Open Structure, Signals (waveform) and List window
view structure
#view list
view signals

# Disable NUMERIC STD Warnings
# This will speed up simulation considerably
# and prevents writing to the transcript file
set NumericStdNoWarnings 1

# Run simulation for 900 ns
run 100 us

# Fill up the waveform in the window
wave zoom full