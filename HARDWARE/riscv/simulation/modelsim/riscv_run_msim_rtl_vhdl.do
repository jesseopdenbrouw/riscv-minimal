transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/processor_common.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/ram_inst.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/processor_common_rom.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/regs.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/instruction_decoder.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/alu.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/pc.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/address_decode.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/ram.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/io.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/riscv.vhd}
vcom -93 -work work {/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/rom.vhd}

do "/mnt/d/PROJECTS/RISCVDEV/HARDWARE/riscv/tb_riscv.do"
