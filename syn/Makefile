include ../CONFIG
include ../../VERSION

FAMILY = virtex5
DEVICE = XC5VLX50T-1FF1136

all:
	@echo "----------------------------------------"
	@echo "Makefile to build UDP Sniffer firmware :"
	@echo "----------------------------------------"
	@echo "Run make with any of the following targets"
	@echo " "
	@echo " netlist  : Generates the netlist for the project for given target board "
	@echo " bits     : Run implementation tools to generate the bitstream
	@echo " download : Downloads the bitstream onto the board"
	@echo " program  : Generate mcs file from bitstream and program the PROM"

netlist: $(POSTSYN_NETLIST)

bits : $(BIT_FILE)

program : $(PROM_FILE)

$(VERSION_FILE): ../../VERSION
	rm -f $@
	echo "assign version_number = 16'h$(FPGA_VER_REGISTER);" >> $@

# Prepare design Defines file based on design parameters
$(DEFINES_FILE):
	/bin/echo "// Design Select" > $(DEFINES_FILE)

ifeq ($(PCIE),true)
	/bin/echo -e "\`define PCIE\n" >> $(DEFINES_FILE)
	/bin/echo -e "\`define PCIE_CORE $(PCIECORE)_$(LANE)_lane\n" >> $(DEFINES_FILE)
	/bin/echo -e "\`define PCIE_LANES $(LANE)\n" >> $(DEFINES_FILE)
endif

ifeq ($(CC),true)
	/bin/echo -e "\`define CC\n" >> $(DEFINES_FILE)
endif

# Prepare HDL design file(s) list
$(LIST_FILE): $(DEFINES_FILE)

# Add PCIE design files
ifeq ($(PCIE),true)
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_bmd.lst >> $(LIST_FILE)
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_$(PCIECORE).lst >> $(LIST_FILE)
	/bin/echo "verilog work ../../rtl/pcie_cc_endpoint/endpoint_blk_plus/source/$(PCIECORE)_$(LANE)_lane.v" >> $(LIST_FILE)
endif

# Add Diamond CC design files
ifeq ($(CC),true)
	/bin/cat ../xilinx/fofb_cc_top.lst >> $(LIST_FILE)
endif

# Add top-level design file
	/bin/echo "verilog work ../../rtl/pcie_cc_top/verilog/pcie_cc_top.v" >> $(LIST_FILE)

# Construct XST script, constraints and top-level design files based
# on design parameters
$(SCR_FILE):
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_xst.scr >> $(SCR_FILE)

$(XCF_FILE):
ifeq ($(PCIE),true)
	/bin/cat ../xilinx/$(FPGA)_$(BOARD)_$(LANE)_lane.xcf >> $(XCF_FILE)
endif

ifeq ($(CC),true)
	/bin/cat ../xilinx/fofb_cc_top.xcf >> $(XCF_FILE)
endif

$(ENDPOINT_DIR):
	rm -rf ../../rtl/pcie_cc_endpoint/endpoint_blk_plus
	ln -sf $(PCIECORE)_$(LANE)_lane $(ENDPOINT_DIR)

$(NETLIST_DIR):
	mkdir $(NETLIST_DIR)

$(COREGEN_NGC_FILES):
	coregen -b $(CC_IP_DIR)/fofb_cc_rx_fifo/coregen/$(FAMILY)/fofb_cc_rx_fifo.xco
	coregen -b $(CC_IP_DIR)/fofb_cc_tx_fifo/coregen/$(FAMILY)/fofb_cc_tx_fifo.xco

$(POSTSYN_NETLIST): $(NETLIST_DIR) $(COREGEN_NGC_FILES) $(VERSION_FILE) $(LIST_FILE) $(SCR_FILE) $(XCF_FILE) $(ENDPOINT_DIR)
	xst -ifn $(SCR_FILE)


#
# P&R parameters
#
NGDBUILD_FLAGS = -sd $(NETLIST_DIR)
MAP_FLAGS      = -w
#MAP_FLAGS      = -w -pr b -timing -logic_opt on -global_opt speed -ol high -xe n
PAR_FLAGS      = -w
TRCE_FLAGS     = -u 20 -v 200
BITGEN_FLAGS   = -g ConfigRate:20


$(UCF_FILE):
ifeq ($(PCIE),true)
	/bin/cat ../constr/$(FPGA)_$(BOARD)_$(LANE)_lane.ucf >> $(UCF_FILE)
endif

ifeq ($(CC),true)
	/bin/cat ../constr/fofb_cc_top.ucf >> $(UCF_FILE)
endif

$(BIT_FILE): $(POSTSYN_NETLIST) $(UCF_FILE)
	ngdbuild -uc $(UCF_FILE) -p $(DEVICE) $(POSTSYN_NETLIST) $(NGDBUILD_FLAGS)
	map $(MAP_FLAGS) -p $(DEVICE) $(NGD_FILE) -o $(MAPPED_NCD_FILE)
	par $(PAR_FLAGS) $(MAPPED_NCD_FILE) $(ROUTED_NCD_FILE)
	bitgen $(BITGEN_FLAGS) $(ROUTED_NCD_FILE)

download: $(BIT_FILE)
	ssh iu42@$(JTAG_PC) 'cd $(CURDIR);$(XILINX)/bin/lin/impact -batch ../xilinx/$(FPGA)_$(BOARD)_loadFPGA.cmd'

$(PROM_FILE): $(BIT_FILE)
	promgen -w -p mcs -c FF -o $(PROM_FILE) -ver 0 $(BIT_FILE) -ver 1 pcie_cc_top.bit -x xcf32p

	ssh iu42@$(JTAG_PC) 'cd $(CURDIR);$(XILINX)/bin/lin/impact -batch ../xilinx/$(FPGA)_$(BOARD)_loadPROM.cmd'

# Clean implementation files
clean:
	rm -rf ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
	rm -rf $(VERSION_FILE)
	rm -rf ../run/*

hwclean:
	rm -rf ../implementation
	rm -rf ../../rtl/pcie_cc_top/verilog/pcie_cc_top_defines.v
	rm -rf $(VERSION_FILE)
	rm -rf ../run/*


