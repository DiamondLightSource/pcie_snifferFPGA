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
	vlog -work work ../../../rtl/pcie_cc_bmd/verilog/common/BMD_64_RWDMA_FSM.v
	vlog -work work ../bench/bmd_64_rwdma_fsm_tb.v
	vlog -work work /dls_sw/apps/FPGA/Xilinx10.1i/ISE/verilog/src/glbl.v

sim:
	vsim $(CMD_FLAG) +notimingchecks +TESTNAME=$(TESTNAME) -L work -L secureip -L unisims_ver $(DOFILE) work.bmd_64_rwdma_fsm_tb glbl $(DUMPVCD)

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
