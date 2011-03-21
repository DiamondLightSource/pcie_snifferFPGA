vlib work
vmap work

vlog -work work ../bench/sys_clk_gen.v
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL_DELAY.v
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/BMD_64_TX_ENGINE.v
vlog -work work ../bench/bmd_64_tx_engine_tb.sv
vlog -work work /dls_sw/apps/FPGA/Xilinx/13.1/ISE_DS/ISE/verilog/src/glbl.v

vsim -novopt -L work -L secureip -L unisims_ver -do vsim.do work.bmd_64_tx_engine_tb glbl
