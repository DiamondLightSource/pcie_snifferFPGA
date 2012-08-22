#
# Xilinx ISE Environment
#
PLATFORM = $(shell uname -m)

ifeq ($(PLATFORM),x86_64)
	ISE=source /dls_sw/apps/FPGA/Xilinx/14.2/14.2/ISE_DS/settings64.sh > /dev/null
endif

ifeq ($(PLATFORM),i686)
	ISE=source /dls_sw/apps/FPGA/Xilinx/14.2/14.2/ISE_DS/settings32.sh > /dev/null
endif

#
# Print the names of unlocked (unconstrainted) IOs
#
export XIL_PAR_DESIGN_CHECK_VERBOSE=1

#
# Name of the PC to be used for programming the FPGA
#
JTAG_PC = pc0003

#
# Hardware Platform Settings
#
FPGA = v5
BOARD = ml555
LANE = 4

#
# FPGA Design Parameters
#
PCIE = true
CC = true
PCIECORE = endpoint_blk_plus_v1_15

main:
	$(ISE) && make -C syn/run -f ../Makefile PCIE=$(PCIE) CC=$(CC) PCIECORE=$(PCIECORE) FPGA=$(FPGA) BOARD=$(BOARD) LANE=$(LANE) bits

download:
	$(ISE) && make -C syn/run -f ../Makefile PCIE=$(PCIE) CC=$(CC) PCIECORE=$(PCIECORE) FPGA=$(FPGA) BOARD=$(BOARD) LANE=$(LANE) JTAG_PC=$(JTAG_PC) download

program:
	$(ISE) && make -C syn/run -f ../Makefile PCIE=$(PCIE) CC=$(CC) PCIECORE=$(PCIECORE) FPGA=$(FPGA) BOARD=$(BOARD) LANE=$(LANE) JTAG_PC=$(JTAG_PC) program

clean:
	make -C syn/run -f ../Makefile clean

hwclean:
	make -C syn/run -f ../Makefile hwclean
