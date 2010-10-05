// PCI-Express Test Bench
//---------------------------------
+define+BOARDx04
+define+SIM_USERTB
+define+SIMULATION
+incdir+../+../tests+../dsport
+incdir+../../rtl/pcie_cc_top/verilog/

../board.v
../sys_clk_gen.v
../sys_clk_gen_ds.v

// PCI-Express 4 Lane Endpoint DMA Reference Design
//-------------------------------------------------
../../rtl/pcie_cc_top/verilog/pcie_cc_top.v
../../rtl/pcie_cc_bmd/verilog/v5_blk_plus_pci_exp_64b_app.v
../../rtl/pcie_cc_bmd/verilog/common/BMD.v
../../rtl/pcie_cc_bmd/verilog/BMD_64_RX_ENGINE.v
../../rtl/pcie_cc_bmd/verilog/BMD_64_TX_ENGINE.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_CFG_CTRL.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_EP.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_EP_MEM.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_EP_MEM_ACCESS.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_INTR_CTRL.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_TO_CTRL.v
../../rtl/pcie_cc_bmd/verilog/common/BMD_64_RWDMA_FSM.v



//Xilinx PCI Express Root Complex Model
//--------------------------------------------
../dsport/xilinx_pci_exp_downstream_port.v
../dsport/xilinx_pci_exp_dsport.v
../dsport/dsport_cfg.v
../dsport/pci_exp_usrapp_rx.v
../dsport/pci_exp_usrapp_tx.v
../dsport/pci_exp_usrapp_com.v
../dsport/pci_exp_usrapp_cfg.v
../dsport/pci_exp_4_lane_64b_dsport.v

