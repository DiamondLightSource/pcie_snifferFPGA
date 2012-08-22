vlib work
vmap work

vlog -work work ../bench/sys_clk_gen.v
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_64_RWDMA_FSM.v
vlog -work work ../bench/bmd_64_rwdma_fsm_tb.v
vlog -work work /dls_sw/apps/FPGA/Xilinx/14.2/14.2/ISE_DS/ISE/verilog/src/glbl.v

vsim +notimingchecks -novopt -L work -L secureip -L unisims_ver work.bmd_64_rwdma_fsm_tb glbl

view wave

add wave -radix Hexadecimal /bmd_64_rwdma_fsm_tb/uut/*

configure wave -signalnamewidth 1

run -all

