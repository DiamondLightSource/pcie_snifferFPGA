onerror resume
onbreak resume
onElabError resume

view wave

add wave -radix Hexadecimal -group "ds_port"       /board/xilinx_pci_exp_4_lane_downstream_port/*

add wave -radix Hexadecimal -group "pci_exp_ep"    /board/pcie_cc_top/*

add wave -radix Hexadecimal -group "ep"            /board/pcie_cc_top/app/BMD/BMD_EP/*

add wave -radix Hexadecimal -group "ep_mem"        /board/pcie_cc_top/app/BMD/BMD_EP/EP_MEM/EP_MEM/*

add wave -radix Hexadecimal -group "ep_mem_access"        /board/pcie_cc_top/app/BMD/BMD_EP/EP_MEM/*

add wave -radix Hexadecimal -group "ep_tx"         /board/pcie_cc_top/app/BMD/BMD_EP/EP_TX/*

add wave -radix Hexadecimal -group "ep_rx"         /board/pcie_cc_top/app/BMD/BMD_EP/EP_RX/*

add wave -radix Hexadecimal -group "bmd_intr_ctrl" /board/pcie_cc_top/app/BMD/BMD_EP/EP_TX/BMD_INTR_CTRL/*

add wave -radix Hexadecimal -group "bmd_cfg_ctrl" /board/pcie_cc_top/app/BMD/BMD_CF/*

add wave -radix Hexadecimal -group "PCIE: CFG BRAM" /board/pcie_cc_top/app/BMD/BMD_EP/EP_MEM/fofb_cc_cfg_bram/*

add wave -radix Hexadecimal -group "CC: CLK IF" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/clk_if/*

add wave -radix Hexadecimal -group "CC: TOP" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/*

add wave -radix Hexadecimal -group "CC: GTP IF" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/gt_if/*

add wave -radix Hexadecimal -group "CC: RX_LL_0" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/gt_if/gtp_lane_gen__0/lanes/rx_ll/*

add wave -radix Hexadecimal -group "CC: FOD" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/fofb_cc_fod/*

add wave -radix Hexadecimal -group "CC: FRAME CTRL" /board/pcie_cc_top/fofb_cc_top_inst/fofb_cc_top/fofb_cc_frame_cntrl/*

add wave -radix Hexadecimal -group "CC_TESTER: TOP" /board/fofb_cc_top_tester/*

add wave -radix Hexadecimal -group "fofb_cc_top_inst_TESTER: TX USRAPP" /board/fofb_cc_top_tester/tx_usrapp/*

add wave -radix Hexadecimal -group "CC_TESTER: RX USRAPP" /board/fofb_cc_top_tester/rx_usrapp/*

add wave -radix Hexadecimal -group "RWDMA_FSM" /board/pcie_cc_top/app/BMD/BMD_EP/BMD_64_RWDMA_FSM/*

configure wave -signalnamewidth 1

run -all

