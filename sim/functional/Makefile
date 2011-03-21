# Virtex 2Pro is not supported by ISE 11.1i. For this simulation, we require Xilinx ISE 10.1i and Modelsim 5.5 installed

ISE = source /dls_sw/apps/FPGA/Xilinx/10.1/ISE/settings32.sh


export LMC_HOME=/dls_sw/apps/FPGA/Xilinx/10.1/ISE/smartmodel/lin/installed_lin
PATH := /dls_sw/apps/FPGA/Questa/6.5b/questasim/linux:$(PATH)
#PATH := /dls_sw/apps/FPGA/Questa/10.0/questasim/linux:$(PATH)

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
	$(ISE) && vcom -f fofb_cc_top.f
	$(ISE) && vlog -work work -f endpoint_blk_plus.f
	$(ISE) && vlog -work work /dls_sw/apps/FPGA/Xilinx/10.1/ISE/verilog/src/glbl.v
	$(ISE) && vlog -work work -f board_rtl_x04.f

sim:
	$(ISE) && vsim $(CMD_FLAG) +notimingchecks +TESTNAME=$(TESTNAME) -L work -L secureip -L unisims_ver $(DOFILE) work.board glbl $(DUMPVCD)

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
