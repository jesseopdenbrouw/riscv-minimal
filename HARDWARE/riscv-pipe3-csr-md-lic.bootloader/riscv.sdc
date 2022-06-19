#
# This file is part of the THUAS RISC-V Minimal Project
#
# (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
#
# riscv.sdc - Constraints file

# This software is for educational purposes only. 
# This software is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

#  50.00 MHz
#create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]
#  66.67 MHz
#create_clock -name {clk} -period 15.000 -waveform { 0.000 7.500 } [get_ports {clk}]
#  100.00 MHz
create_clock -name {I_clk} -period 10.000 -waveform { 0.000 5.000 } [get_ports {I_clk}]
#  125.00 MHz
#create_clock -name {clk} -period 8.000 -waveform { 0.000 4.000 } [get_ports {clk}]
# 166.67 MHz
#create_clock -name {clk} -period 6.000 -waveform { 0.000 3.000 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {I_clk}] -rise_to [get_clocks {I_clk}]  0.1 
set_clock_uncertainty -rise_from [get_clocks {I_clk}] -fall_to [get_clocks {I_clk}]  0.1
set_clock_uncertainty -fall_from [get_clocks {I_clk}] -rise_to [get_clocks {I_clk}]  0.1
set_clock_uncertainty -fall_from [get_clocks {I_clk}] -fall_to [get_clocks {I_clk}]  0.1


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

