vlib work
vmap work

vcom -work work ../../../rtl/FastFeedbackFPGA/rtl/fofb_cc_dpbram/rtl/vhdl/fofb_cc_sdpbram.vhd
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v
vlog -work work ../../../rtl/pcie_cc_bmd/verilog/BMD_64_TX_ENGINE.v
vlog -work work ../bench/bmd_tx_engine_tb.v
vlog -work work /dls_sw/apps/FPGA/Xilinx10.1i/ISE/verilog/src/glbl.v

vsim -L work -L secureip -L unisims_ver -do vsim.do work.bmd_tx_engine_tb glbl

