include ../../VERSION

#
# ISE environment variable
#
export XILINX=/dls_sw/apps/FPGA/Xilinx/12.1/ISE_DS/ISE
export PATH:=${XILINX}/bin/lin:${PATH}

#
#
# Print the names of unlocked (unconstrainted) IOs
#
export XIL_PAR_DESIGN_CHECK_VERBOSE=1

VERSION_FILE = ../../rtl/pcie_cc_bmd/verilog/common/pcie_cc_version.v

#
# Name of the PC to be used for programming the FPGA
#
JTAG_PC = pc0035

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
PCIECORE = endpoint_blk_plus_v1_14

#
# P&R parameters
#
NGDBUILD_OPTIONS = -aul -verbose
MAP_OPTIONS      = -w -pr b -timing -logic_opt on -global_opt speed -retiming on -register_duplication -ol high -xe n
PAR_OPTIONS      = -ol high
TRCE_OPTIONS     = -u 20 -v 200
BITGEN_OPTIONS   = -g ConfigRate:20

main: all

# Clean implementation files
clean:
	rm -rf ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
	rm -rf $(VERSION_FILE)
	rm -rf ../run/*

#
# Prepare version file
#
$(VERSION_FILE): ../../VERSION
	rm -f $@
	echo "assign version_number = 16'h$(FPGA_VER_REGISTER);" >> $@


#
# Prepare design Defines file based on design parameters
#
../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v:
	/bin/echo "// Design Select" > ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v

ifeq ($(PCIE),true)
	/bin/echo -e "\`define PCIE\n" >> ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
	/bin/echo -e "\`define PCIE_CORE $(PCIECORE)_$(LANE)_lane\n" >> ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
	/bin/echo -e "\`define PCIE_LANES $(LANE)\n" >> ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
endif

ifeq ($(CC),true)
	/bin/echo -e "\`define CC\n" >> ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
endif

#
# Prepare HDL design file(s) list
#
pcie_cc_top.lst: ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v

# Add PCIE design files
ifeq ($(PCIE),true)
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_bmd.lst >> pcie_cc_top.lst
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_$(PCIECORE).lst >> pcie_cc_top.lst
	/bin/echo "verilog work ../../rtl/pcie_cc_endpoint/endpoint_blk_plus/source/$(PCIECORE)_$(LANE)_lane.v" >> pcie_cc_top.lst
endif

# Add Diamond CC design files
ifeq ($(CC),true)
	/bin/cat ../xilinx/fofb_cc_top.lst >> pcie_cc_top.lst
endif

# Add top-level design file
	/bin/echo "verilog work ../../rtl/pcie_cc_top/verilog/pcie_cc_top.v" >> pcie_cc_top.lst


#
# Construct XST script, constraints and top-level design files based
# on design parameters
#
pcie_cc_top.scr:
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_xst.scr >> pcie_cc_top.scr

pcie_cc_top.xcf:
ifeq ($(PCIE),true)
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_$(LANE)_lane.xcf >> pcie_cc_top.xcf
endif

ifeq ($(CC),true)
	/bin/cat ../xilinx/fofb_cc_top.xcf >> pcie_cc_top.xcf
endif

pcie_cc_endpoint:
	rm -rf ../../rtl/pcie_cc_endpoint/endpoint_blk_plus
	ln -sf $(PCIECORE)_$(LANE)_lane ../../rtl/pcie_cc_endpoint/endpoint_blk_plus

#
# Construct UCF file
#
pcie_cc_top.ucf:
ifeq ($(PCIE),true)
	/bin/cat ../constr/$(FPGA)_$(BOARD)_$(LANE)_lane.ucf >> pcie_cc_top.ucf
endif

ifeq ($(CC),true)
	/bin/cat ../constr/fofb_cc_top.ucf >> pcie_cc_top.ucf
endif

#
# Run XST synthesis
#
pcie_cc_top.ngc: $(VERSION_FILE) pcie_cc_top.lst pcie_cc_top.scr pcie_cc_top.xcf pcie_cc_endpoint
	xst -ifn pcie_cc_top.scr

#
# Run SmartXplorer
#
pcie_cc_top.smart: pcie_cc_top.ucf
	smartxplorer -p xc5vlx50t-ff1136-1 -uc pcie_cc_top.ucf -wd smartxplorer_results -sd '.;../../rtl/FastFeedbackFPGA/rtl/fofb_cc_tx_fifo/coregen/virtex5/;../../rtl/FastFeedbackFPGA/rtl/fofb_cc_rx_fifo/coregen/virtex5/;' -m 12 -ra pcie_cc_top.ngc -l ../xilinx/hosts.lst -rcmd ssh

#
# Run NGDBuild
#
pcie_cc_top.ngd: pcie_cc_top.ucf
	ngdbuild $(NGDBUILD_OPTIONS) -uc pcie_cc_top.ucf pcie_cc_top.ngc -sd ../../rtl/FastFeedbackFPGA/rtl/fofb_cc_tx_fifo/coregen/virtex5/ -sd ../../rtl/FastFeedbackFPGA/rtl/fofb_cc_rx_fifo/coregen/virtex5/ -sd ../chipscope/

#
# Run MAP
#
pcie_cc_top_map.ncd:
	map $(MAP_OPTIONS) -o pcie_cc_top_map.ncd pcie_cc_top.ngd pcie_cc_top.pcf

#
# Run PAR
#
pcie_cc_top.ncd:
	par $(PAR_OPTIONS) -w pcie_cc_top_map.ncd pcie_cc_top.ncd pcie_cc_top.pcf

#
# Run BITGEN
#
pcie_cc_top.bit:
	bitgen $(BITGEN_OPTIONS) -w pcie_cc_top.ncd

#
# Run PROMGEN 
#
pcie_cc_top.mcs:
	promgen -w -p mcs -c FF -o pcie_cc_top -ver 0 pcie_cc_top.bit -ver 1 pcie_cc_top.bit -x xcf32p

#
# Program FPGA
#
pcie_cc_top.fpga:
	ssh iu42@$(JTAG_PC) 'cd $(CURDIR);$(XILINX)/bin/lin/impact -batch ../xilinx/$(FPGA)_$(BOARD)_loadFPGA.cmd'

#
# Program PROM
#
pcie_cc_top.prom: pcie_cc_top.mcs
	ssh iu42@$(JTAG_PC) 'cd $(CURDIR);$(XILINX)/bin/lin/impact -batch ../xilinx/$(FPGA)_$(BOARD)_loadPROM.cmd'

#
# Make run
#
smart: clean pcie_cc_top.ngc pcie_cc_top.smart
all: clean pcie_cc_top.ngc pcie_cc_top.ngd pcie_cc_top_map.ncd pcie_cc_top.ncd pcie_cc_top.bit pcie_cc_top.fpga
