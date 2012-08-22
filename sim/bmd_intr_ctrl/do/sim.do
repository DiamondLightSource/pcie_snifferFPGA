vlib work

vlog  "../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v"
vlog  "../bench/bmd_intr_ctrl_tb.v"
vlog  "/dls_sw/apps/FPGA/Xilinx/14.2/14.2/ISE_DS/ISE//verilog/src/glbl.v"

vsim -voptargs="+acc" -t 1ps  -L xilinxcorelib_ver -L unisims_ver -L unimacro_ver -L secureip -lib work work.bmd_intr_ctrl_tb glbl

view wave
add wave *

run 10us

