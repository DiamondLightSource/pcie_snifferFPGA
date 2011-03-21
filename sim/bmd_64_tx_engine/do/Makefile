PATH := /dls_sw/apps/FPGA/Questa/10.0/questasim/linux:$(PATH)


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
	vlog -work work ../bench/sys_clk_gen.v
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL_DELAY.v
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/BMD_64_TX_ENGINE.v
	vlog -work work ../bench/bmd_64_tx_engine_tb.sv
	vlog -work work /dls_sw/apps/FPGA/Xilinx/13.1/ISE_DS/ISE/verilog/src/glbl.v

sim:
	vsim $(CMD_FLAG) -novopt +notimingchecks +TESTNAME=$(TESTNAME) -L work -L secureip -L unisims_ver $(DOFILE) work.bmd_64_tx_engine_tb glbl $(DUMPVCD)

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
