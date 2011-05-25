`include "pcie_cc_top_defines.v"

module pcie_cc_top (
`ifdef PCIE
    // PCI Express Fabric Interface
    pci_exp_txp,
    pci_exp_txn,
    pci_exp_rxp,
    pci_exp_rxn,

    // System (SYS) Interface
    sys_clk_p,
    sys_clk_n,
    sys_reset_n,
//    refclkout,
`endif

`ifdef CC
    // ICS Clock Synth 2 Interface
    mgt_clksel,
    ics_clk,
    strobe,
    pload,
    sdata,
    sclock,

    // GTP Interface
    gtp_clk_p,
    gtp_clk_n,
    sfp_txp,
    sfp_txn,
    sfp_rxp,
    sfp_rxn
`endif
);
//synthesis syn_noclockbuf=1

parameter SIM_GTPRESET_SPEEDUP = 0;
parameter LANE_COUNT           = 1;


`ifdef PCIE
//-------------------------------------------------------
// PCI Express Fabric Interface
//-------------------------------------------------------

// Tx
output [ (`PCIE_LANES - 1):0]      pci_exp_txp;
output [ (`PCIE_LANES - 1):0]      pci_exp_txn;

// Rx
input  [ (`PCIE_LANES - 1):0]      pci_exp_rxp;
input  [ (`PCIE_LANES - 1):0]      pci_exp_rxn;

//-------------------------------------------------------
// System (SYS) Interface
//-------------------------------------------------------

input                   sys_clk_p;
input                   sys_clk_n;
input                   sys_reset_n;

`endif

`ifdef CC
//-------------------------------------------------------
// System (SYS) Interface
//-------------------------------------------------------
output                  mgt_clksel;
input                   ics_clk;
output                  strobe;
output                  pload;
output                  sdata;
output                  sclock;

//-------------------------------------------------------
// System (SYS) Interface
//-------------------------------------------------------
input                   gtp_clk_p;
input                   gtp_clk_n;
output [(LANE_COUNT - 1):0]      sfp_txp;
output [(LANE_COUNT - 1):0]      sfp_txn;
input  [(LANE_COUNT - 1):0]      sfp_rxp;
input  [(LANE_COUNT - 1):0]      sfp_rxn;
`endif

/*
 * Local Wires
 */

wire                    sys_clk_c;
wire                    sys_reset_n_c; 
wire                    trn_clk_c;//synthesis attribute max_fanout of trn_clk_c is "100000"
wire                    trn_reset_n_c;
wire                    trn_lnk_up_n_c;
wire                    cfg_trn_pending_n_c;
wire [(64 - 1):0]       cfg_dsn_n_c;
wire                    trn_tsof_n_c;
wire                    trn_teof_n_c;
wire                    trn_tsrc_rdy_n_c;
wire                    trn_tdst_rdy_n_c;
wire                    trn_tsrc_dsc_n_c;
wire                    trn_terrfwd_n_c;
wire                    trn_tdst_dsc_n_c;
wire [(64 - 1):0]       trn_td_c;
wire [7:0]              trn_trem_n_c;
wire [( 4 -1 ):0]       trn_tbuf_av_c;

wire                    trn_rsof_n_c;
wire                    trn_reof_n_c;
wire                    trn_rsrc_rdy_n_c;
wire                    trn_rsrc_dsc_n_c;
wire                    trn_rdst_rdy_n_c;
wire                    trn_rerrfwd_n_c;
wire                    trn_rnp_ok_n_c;

wire [(64 - 1):0]       trn_rd_c;
wire [7:0]              trn_rrem_n_c;
wire [6:0]              trn_rbar_hit_n_c;
wire [7:0]              trn_rfc_nph_av_c;
wire [11:0]             trn_rfc_npd_av_c;
wire [7:0]              trn_rfc_ph_av_c;
wire [11:0]             trn_rfc_pd_av_c;
wire                    trn_rcpl_streaming_n_c;

wire [31:0]             cfg_di_c;
wire [3:0]              cfg_byte_en_n_c;
wire [47:0]             cfg_err_tlp_cpl_header_c;

wire                    cfg_wr_en_n_c;
wire                    cfg_err_cor_n_c;
wire                    cfg_err_ur_n_c;
wire                    cfg_err_cpl_rdy_n_c;
wire                    cfg_err_ecrc_n_c;
wire                    cfg_err_cpl_timeout_n_c;
wire                    cfg_err_cpl_abort_n_c;
wire                    cfg_err_cpl_unexpect_n_c;
wire                    cfg_err_posted_n_c;
wire                    cfg_err_locked_n_c;
wire                    cfg_interrupt_n_c;
wire                    cfg_interrupt_rdy_n_c;

wire                    cfg_interrupt_assert_n_c;
wire [7 : 0]            cfg_interrupt_di_c;
wire [7 : 0]            cfg_interrupt_do_c;
wire [2 : 0]            cfg_interrupt_mmenable_c;
wire                    cfg_interrupt_msienable_c;

wire                    cfg_pm_wake_n_c;
wire [ 2: 0]            cfg_pcie_link_state_n_c;
wire [ 7: 0]            cfg_bus_number_c;
wire [ 4: 0]            cfg_device_number_c;
wire [ 2: 0]            cfg_function_number_c;
wire [15: 0]            cfg_status_c;
wire [15: 0]            cfg_command_c;
wire [15: 0]            cfg_dstatus_c;
wire [15: 0]            cfg_dcommand_c;
wire [15: 0]            cfg_lcommand_c;

/*
 * DLS CC Wires
 */
wire [10: 0]            fai_cfg_a;
wire [31: 0]            fai_cfg_do;
wire [31: 0]            fai_cfg_di;
wire                    fai_cfg_we;
wire                    fai_cfg_clk;
wire [31: 0]            fai_cfg_val;
wire [9:0]              xy_buf_addr;
wire [63:0]             xy_buf_dat;
wire                    timeframe_end_rise;
wire [255:0]            fofb_node_mask;
wire                    fofb_dma_ok;
wire                    fofb_rxlink_up;
wire [9:0]              fofb_rxlink_partner;
wire [15: 0]            harderror_cnt;
wire [15: 0]            softerror_cnt;
wire [15: 0]            frameerror_cnt;

`ifdef PCIE
/*
 * Virtex5-FX PCI-E 100 MHz Global Clock Buffer
 */
IBUFDS refclk_ibuf (
    .O                          ( sys_clk_c                 ),
    .I                          ( sys_clk_p                 ),
    .IB                         ( sys_clk_n                 )
);

/*
 * System Reset Input Pad Instance
 */
IBUF sys_reset_n_ibuf (
    .O                          ( sys_reset_n_c             ),
    .I                          ( sys_reset_n               )
);

/*
 * Endpoint Implementation Application
 */

pci_exp_64b_app app (
    //
    // Transaction ( TRN ) Interface
    //
    .trn_clk                    ( trn_clk_c                 ), // I
    .trn_reset_n                ( trn_reset_n_c             ), // I
    .trn_lnk_up_n               ( trn_lnk_up_n_c            ), // I

    // Tx Local-Link
    .trn_td                     ( trn_td_c                  ), // O [63/31:0]
    .trn_trem                   ( trn_trem_n_c              ), // O [7:0]
    .trn_tsof_n                 ( trn_tsof_n_c              ), // O
    .trn_teof_n                 ( trn_teof_n_c              ), // O
    .trn_tsrc_rdy_n             ( trn_tsrc_rdy_n_c          ), // O
    .trn_tsrc_dsc_n             ( trn_tsrc_dsc_n_c          ), // O
    .trn_tdst_rdy_n             ( trn_tdst_rdy_n_c          ), // I
    .trn_tdst_dsc_n             ( trn_tdst_dsc_n_c          ), // I
    .trn_terrfwd_n              ( trn_terrfwd_n_c           ), // O
    .trn_tbuf_av                ( trn_tbuf_av_c             ), // I [4/3:0]

    // Rx Local-Link
    .trn_rd( trn_rd_c ),                     // I [63/31:0]
    .trn_rrem                   ( trn_rrem_n_c              ), // I [7:0]
    .trn_rsof_n                 ( trn_rsof_n_c              ), // I
    .trn_reof_n                 ( trn_reof_n_c              ), // I
    .trn_rsrc_rdy_n             ( trn_rsrc_rdy_n_c          ), // I
    .trn_rsrc_dsc_n             ( trn_rsrc_dsc_n_c          ), // I
    .trn_rdst_rdy_n             ( trn_rdst_rdy_n_c          ), // O
    .trn_rerrfwd_n              ( trn_rerrfwd_n_c           ), // I
    .trn_rnp_ok_n               ( trn_rnp_ok_n_c            ), // O
    .trn_rbar_hit_n             ( trn_rbar_hit_n_c          ), // I [6:0]
    .trn_rfc_npd_av             ( trn_rfc_npd_av_c          ), // I [11:0]
    .trn_rfc_nph_av             ( trn_rfc_nph_av_c          ), // I [7:0]
    .trn_rfc_pd_av              ( trn_rfc_pd_av_c           ), // I [11:0]
    .trn_rfc_ph_av              ( trn_rfc_ph_av_c           ), // I [7:0]
    .trn_rcpl_streaming_n       ( trn_rcpl_streaming_n_c    ), // O

    //
    // Host ( CFG ) Interface
    //
    .cfg_di                     ( cfg_di_c                  ), // O [31:0]
    .cfg_byte_en_n              ( cfg_byte_en_n_c           ), // O
    .cfg_wr_en_n                ( cfg_wr_en_n_c             ), // O
    .cfg_err_cor_n              ( cfg_err_cor_n_c           ), // O
    .cfg_err_ur_n               ( cfg_err_ur_n_c            ), // O
    .cfg_err_cpl_rdy_n          ( cfg_err_cpl_rdy_n_c       ), // I
    .cfg_err_ecrc_n             ( cfg_err_ecrc_n_c          ), // O
    .cfg_err_cpl_timeout_n      ( cfg_err_cpl_timeout_n_c   ), // O
    .cfg_err_cpl_abort_n        ( cfg_err_cpl_abort_n_c     ), // O
    .cfg_err_cpl_unexpect_n     ( cfg_err_cpl_unexpect_n_c  ), // O
    .cfg_err_posted_n           ( cfg_err_posted_n_c        ), // O
    .cfg_err_tlp_cpl_header     ( cfg_err_tlp_cpl_header_c  ), // O [47:0]
    .cfg_interrupt_n            ( cfg_interrupt_n_c         ), // O
    .cfg_interrupt_rdy_n        ( cfg_interrupt_rdy_n_c     ), // I

    .cfg_interrupt_assert_n     ( cfg_interrupt_assert_n_c  ), // O
    .cfg_interrupt_di           ( cfg_interrupt_di_c        ), // O [7:0]
    .cfg_interrupt_do           ( cfg_interrupt_do_c        ), // I [7:0]
    .cfg_interrupt_mmenable     ( cfg_interrupt_mmenable_c  ), // I [2:0]
    .cfg_interrupt_msienable    ( cfg_interrupt_msienable_c ), // I
    .cfg_pm_wake_n              ( cfg_pm_wake_n_c           ), // O
    .cfg_pcie_link_state_n      ( cfg_pcie_link_state_n_c   ), // I [2:0]
    .cfg_trn_pending_n          ( cfg_trn_pending_n_c       ), // O
    .cfg_dsn                    ( cfg_dsn_n_c               ), // O [63:0]

    .cfg_bus_number             ( cfg_bus_number_c          ), // I [7:0]
    .cfg_device_number          ( cfg_device_number_c       ), // I [4:0]
    .cfg_function_number        ( cfg_function_number_c     ), // I [2:0]
    .cfg_status                 ( cfg_status_c              ), // I [15:0]
    .cfg_command                ( cfg_command_c             ), // I [15:0]
    .cfg_dstatus                ( cfg_dstatus_c             ), // I [15:0]
    .cfg_dcommand               ( cfg_dcommand_c            ), // I [15:0]
    .cfg_lcommand               ( cfg_lcommand_c            ), // I [15:0]

    // FOFB CC Interface
    .fai_cfg_a_i                ( fai_cfg_a                 ),
    .fai_cfg_do_i               ( fai_cfg_do                ),
    .fai_cfg_di_o               ( fai_cfg_di                ),
    .fai_cfg_we_i               ( fai_cfg_we                ),
    .fai_cfg_clk_i              ( fai_cfg_clk               ),
    .fai_cfg_val_o              ( fai_cfg_val               ),
    .xy_buf_addr_o              ( xy_buf_addr               ),
    .xy_buf_dat_i               ( xy_buf_dat                ),
    .timeframe_end_rise_i       ( timeframe_end_rise        ),
    .fofb_node_mask_i           ( fofb_node_mask            ),
    .fofb_dma_ok_o              ( fofb_dma_ok               ),
    .fofb_rxlink_up_i           ( fofb_rxlink_up            ),
    .fofb_rxlink_partner_i      ( fofb_rxlink_partner       ),
    .harderror_cnt_i            ( harderror_cnt             ),
    .softerror_cnt_i            ( softerror_cnt             ),
    .frameerror_cnt_i           ( frameerror_cnt            )
);

/*
 * Xilinx Endpoint Core
 */

`PCIE_CORE ep  (
    //
    // PCI Express Fabric Interface
    //
    .pci_exp_txp                ( pci_exp_txp               ), // O [7/3/0:0]
    .pci_exp_txn                ( pci_exp_txn               ), // O [7/3/0:0]
    .pci_exp_rxp                ( pci_exp_rxp               ), // O [7/3/0:0]
    .pci_exp_rxn                ( pci_exp_rxn               ), // O [7/3/0:0]

    //
    // System ( SYS ) Interface
    //
    .sys_clk                    ( sys_clk_c                 ), // I
    .sys_reset_n                ( sys_reset_n_c             ), // I
    .refclkout                  (                           ), // O

    //
    // Transaction ( TRN ) Interface
    //
    .trn_clk                    ( trn_clk_c                 ), // O
    .trn_reset_n                ( trn_reset_n_c             ), // O
    .trn_lnk_up_n               ( trn_lnk_up_n_c            ), // O

    // Tx Local-Link
    .trn_td                     ( trn_td_c                  ), // I [63/31:0]
    .trn_trem_n                 ( trn_trem_n_c              ), // I [7:0]
    .trn_tsof_n                 ( trn_tsof_n_c              ), // I
    .trn_teof_n                 ( trn_teof_n_c              ), // I
    .trn_tsrc_rdy_n             ( trn_tsrc_rdy_n_c          ), // I
    .trn_tsrc_dsc_n             ( trn_tsrc_dsc_n_c          ), // I
    .trn_tdst_rdy_n             ( trn_tdst_rdy_n_c          ), // O
    .trn_tdst_dsc_n             ( trn_tdst_dsc_n_c          ), // O
    .trn_terrfwd_n              ( trn_terrfwd_n_c           ), // I
    .trn_tbuf_av                ( trn_tbuf_av_c             ), // O [4/3:0]

    // Rx Local-Link
    .trn_rd                     ( trn_rd_c                  ), // O [63/31:0]
    .trn_rrem_n                 ( trn_rrem_n_c              ), // O [7:0]
    .trn_rsof_n                 ( trn_rsof_n_c              ), // O
    .trn_reof_n                 ( trn_reof_n_c              ), // O
    .trn_rsrc_rdy_n             ( trn_rsrc_rdy_n_c          ), // O
    .trn_rsrc_dsc_n             ( trn_rsrc_dsc_n_c          ), // O
    .trn_rdst_rdy_n             ( trn_rdst_rdy_n_c          ), // I
    .trn_rerrfwd_n              ( trn_rerrfwd_n_c           ), // O
    .trn_rnp_ok_n               ( trn_rnp_ok_n_c            ), // I
    .trn_rbar_hit_n             ( trn_rbar_hit_n_c          ), // O [6:0]
    .trn_rfc_nph_av             ( trn_rfc_nph_av_c          ), // O [11:0]
    .trn_rfc_npd_av             ( trn_rfc_npd_av_c          ), // O [7:0]
    .trn_rfc_ph_av              ( trn_rfc_ph_av_c           ), // O [11:0]
    .trn_rfc_pd_av              ( trn_rfc_pd_av_c           ), // O [7:0]
    .trn_rcpl_streaming_n       ( trn_rcpl_streaming_n_c    ), // I

    //
    // Host ( CFG ) Interface
    //
    .cfg_do                     (                           ), // O [31:0]
    .cfg_rd_wr_done_n           (                           ), // O
    .cfg_di                     ( cfg_di_c                  ), // I [31:0]
    .cfg_byte_en_n              ( cfg_byte_en_n_c           ), // I [3:0]
    .cfg_dwaddr                 ( 10'h0                     ), // I [9:0]
    .cfg_wr_en_n                ( cfg_wr_en_n_c             ), // I
    .cfg_rd_en_n                ( 1'b1                      ), // I

    .cfg_err_cor_n              ( cfg_err_cor_n_c           ), // I
    .cfg_err_ur_n               ( cfg_err_ur_n_c            ), // I
    .cfg_err_cpl_rdy_n          ( cfg_err_cpl_rdy_n_c       ), // O
    .cfg_err_ecrc_n             ( cfg_err_ecrc_n_c          ), // I
    .cfg_err_cpl_timeout_n      ( cfg_err_cpl_timeout_n_c   ), // I
    .cfg_err_cpl_abort_n        ( cfg_err_cpl_abort_n_c     ), // I
    .cfg_err_cpl_unexpect_n     ( cfg_err_cpl_unexpect_n_c  ), // I
    .cfg_err_posted_n           ( cfg_err_posted_n_c        ), // I
    .cfg_err_tlp_cpl_header     ( cfg_err_tlp_cpl_header_c  ), // I [47:0]
    .cfg_err_locked_n           ( 1'b1                      ), // I
    .cfg_interrupt_n            ( cfg_interrupt_n_c         ), // I
    .cfg_interrupt_rdy_n        ( cfg_interrupt_rdy_n_c     ), // O

    .cfg_interrupt_assert_n     ( cfg_interrupt_assert_n_c  ), // I
    .cfg_interrupt_di           ( cfg_interrupt_di_c        ), // I [7:0]
    .cfg_interrupt_do           ( cfg_interrupt_do_c        ), // O [7:0]
    .cfg_interrupt_mmenable     ( cfg_interrupt_mmenable_c  ), // O [2:0]
    .cfg_interrupt_msienable    ( cfg_interrupt_msienable_c ), // O
    .cfg_to_turnoff_n           (                           ), // I
    .cfg_pm_wake_n              ( cfg_pm_wake_n_c           ), // I
    .cfg_pcie_link_state_n      ( cfg_pcie_link_state_n_c   ), // O [2:0]
    .cfg_trn_pending_n          ( cfg_trn_pending_n_c       ), // I
    .cfg_bus_number             ( cfg_bus_number_c          ), // O [7:0]
    .cfg_device_number          ( cfg_device_number_c       ), // O [4:0]
    .cfg_function_number        ( cfg_function_number_c     ), // O [2:0]
    .cfg_status                 ( cfg_status_c              ), // O [15:0]
    .cfg_command                ( cfg_command_c             ), // O [15:0]
    .cfg_dstatus                ( cfg_dstatus_c             ), // O [15:0]
    .cfg_dcommand               ( cfg_dcommand_c            ), // O [15:0]
    .cfg_lstatus                (                           ), // O [15:0]
    .cfg_lcommand               ( cfg_lcommand_c            ), // O [15:0]
    .cfg_dsn                    ( cfg_dsn_n_c               ), // I [63:0]

     // The following is used for simulation only.  Setting
     // the following core input to 1 will result in a fast
     // train simulation to happen.  This bit should not be set
     // during synthesis or the core may not operate properly.
     `ifdef SIMULATION
         .fast_train_simulation_only(1'b1)
     `else
         .fast_train_simulation_only(1'b0)
     `endif
);
`else
    assign fai_cfg_val = 32'h8;
`endif


`ifdef CC
/*
 *
 */
ics_ctrl_if i_ics_ctrl_if (
    .mgt_clksel                 ( mgt_clksel                ),
    .clk                        ( ics_clk                   ),
    .strobe                     ( strobe                    ),
    .pload                      ( pload                     ),
    .sdata                      ( sdata                     ),
    .sclock                     ( sclock                    )
);


/*
 * Communication controller instantiation
 */

fofb_cc_top_wrapper #(
    .SIM_GTPRESET_SPEEDUP       ( SIM_GTPRESET_SPEEDUP      ),
    .LANE_COUNT                 ( LANE_COUNT                )
)
CC (
    .refclk_p_i                 ( gtp_clk_p                 ),
    .refclk_n_i                 ( gtp_clk_n                 ),
    .sysclk_i                   ( trn_clk_c                 ),

    .fai_cfg_a_o                ( fai_cfg_a                 ),
    .fai_cfg_d_o                ( fai_cfg_do                ), // O [31:0]
    .fai_cfg_d_i                ( fai_cfg_di                ), // I [31:0]
    .fai_cfg_we_o               ( fai_cfg_we                ),
    .fai_cfg_clk_o              ( fai_cfg_clk               ),
    .fai_cfg_val_i              ( fai_cfg_val               ),

    .fai_rio_rdp_i              ( sfp_rxp                   ),
    .fai_rio_rdn_i              ( sfp_rxn                   ),
    .fai_rio_tdp_o              ( sfp_txp                   ),
    .fai_rio_tdn_o              ( sfp_txn                   ),

    .xy_buf_addr_i              ( xy_buf_addr[8:0]          ),
    .xy_buf_dat_o               ( xy_buf_dat                ),
    .timeframe_end_rise_o       ( timeframe_end_rise        ),
    .fofb_dma_ok_i              ( fofb_dma_ok               ),
    .fofb_node_mask_o           ( fofb_node_mask            ),
    .fofb_rxlink_up_o           ( fofb_rxlink_up            ),
    .fofb_rxlink_partner_o      ( fofb_rxlink_partner       ),
    .harderror_cnt_o            ( harderror_cnt             ),
    .softerror_cnt_o            ( softerror_cnt             ),
    .frameerror_cnt_o           ( frameerror_cnt            )
);

`endif

/*
 * Chipscope Interface
 */
//wire [35:0]     control0;
//wire [255:0]    data;
//wire [7:0]      trig;
//
//icon i_icon (
//    .control0                   ( control0                  )
//);
//
//ila i_ila (
//    .control                    ( control0                  ),
//    .clk                        ( trn_clk_c                 ),
//    .data                       ( data                      ),
//    .trig0                      ( trig                      )
//);
//
//assign data[0]      = cfg_interrupt_msienable_c;
//assign data[3:1]    = cfg_interrupt_mmenable_c;

endmodule // XILINX_PCI_EXP_EP
