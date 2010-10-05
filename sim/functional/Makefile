# Virtex 2Pro is not supported by ISE 11.1i. For this simulation, we require Xilinx ISE 10.1i and Modelsim 5.5 installed

export LMC_HOME=/dls_sw/apps/FPGA/Xilinx10.1i/ISE/smartmodel/lin/installed_lin
PATH := /dls_sw/apps/FPGA/Questasim65/questasim/linux:$(PATH)

# Test name
TESTNAME = wdmatest

# Dump waveforms into .vcd file with +dump_all flag·
DUMPVCD =

# Run modelsim on command line with -c flag
CMDLINE = false

ifeq ($(CMDLINE),true)
	CMD_FLAG=-c
	DOFILE=-do "run -all"
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
	vcom -f fofb_cc_top.f
	vlog -work work -f endpoint_blk_plus.f
	vlog -work work /dls_sw/apps/FPGA/Xilinx10.1i/ISE/verilog/src/glbl.v
	vlog -work work -f board_rtl_x04.f

sim:
	source /dls_sw/apps/FPGA/Xilinx10.1i/ISE/settings32.sh && vsim $(CMD_FLAG) +notimingchecks +TESTNAME=$(TESTNAME) -L work -L secureip -L unisims_ver $(DOFILE) work.board glbl $(DUMPVCD)

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
