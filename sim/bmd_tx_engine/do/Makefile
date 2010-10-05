PATH := /dls_sw/apps/FPGA/Questasim/questasim/linux:$(PATH)

CMDLINE ?= false	# Run modelsim on command line with -c flag
DUMPVCD ?=			# Dump waveforms into .vcd file with +dump_all flag 

ifeq ($(CMDLINE),true)
	CMD_FLAG=-c
	DOFILE=-do "run 500 us"
else
	CMD_FLAG=
	DOFILE=-do vsim.do
endif

main: all

worklib:
	vlib work

workmap:
	vmap work

compile:
	vcom -work work ../../../rtl/FastFeedbackFPGA/rtl/fofb_cc_dpbram/rtl/vhdl/fofb_cc_sdpbram.vhd
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/BMD_64_TX_ENGINE.v
	vlog -work work ../bench/bmd_tx_engine_tb.v
	vlog -work work /dls_sw/apps/FPGA/Xilinx10.1i/ISE/verilog/src/glbl.v

sim:
	vsim $(CMD_FLAG) -L work -L secureip -L unisims_ver $(DOFILE) work.bmd_tx_engine_tb glbl

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
