/*
 * Filename: BMD_EP.v
 *
 * Description: Bus Master Device I/O Endpoint module. 
 *
 */

`timescale 1ns/1ns

module BMD_EP# (
    parameter INTERFACE_WIDTH = 64,
    parameter INTERFACE_TYPE = 4'b0010,
    parameter FPGA_FAMILY = 8'h14
)
(
    clk,
    rst_n,

    /* LocalLink Tx */
    trn_td,
    trn_trem_n,
    trn_tsof_n,
    trn_teof_n,
    trn_tsrc_dsc_n,
    trn_tsrc_rdy_n,
    trn_tdst_dsc_n,
    trn_tdst_rdy_n,
    trn_tbuf_av,
    trn_tstr_n,

    /* LocalLink Rx */
    trn_rd,
    trn_rrem_n,
    trn_rsof_n,
    trn_reof_n,
    trn_rsrc_rdy_n,
    trn_rsrc_dsc_n,
    trn_rdst_rdy_n,
    trn_rbar_hit_n,
    trn_rnp_ok_n,
    trn_rcpl_streaming_n,

`ifdef PCIE2_0
    pl_directed_link_change,
    pl_ltssm_state,
    pl_directed_link_width,
    pl_directed_link_speed,
    pl_directed_link_auton,
    pl_upstream_preemph_src,
    pl_sel_link_width,
    pl_sel_link_rate,
    pl_link_gen2_capable,
    pl_link_partner_gen2_supported,
    pl_initial_link_width,
    pl_link_upcfg_capable,
    pl_lane_reversal_mode,
`endif

    /* Turnoff access */
    req_compl_o,
    compl_done_o,

    /* Configuration access */
    cfg_interrupt_n,
    cfg_interrupt_rdy_n,
    cfg_interrupt_assert_n,
    cfg_interrupt_di,
    cfg_interrupt_do,
    cfg_interrupt_mmenable,
    cfg_interrupt_msienable,
    cfg_completer_id,
    cfg_ext_tag_en,
    cfg_cap_max_lnk_width,
    cfg_neg_max_lnk_width,
    cfg_cap_max_payload_size,
    cfg_prg_max_payload_size,
    cfg_max_rd_req_size,
    cfg_msi_enable,
    cfg_rd_comp_bound,
    cfg_phant_func_en,
    cfg_phant_func_supported,
    cfg_bus_mstr_enable,

    cpld_data_size_hwm,
    cpld_size,
    cur_rd_count_hwm,
    cur_mrd_count,

    fai_cfg_val_o,
    xy_buf_addr_o,
    xy_buf_dat_i,
    timeframe_end_rise_i,
    fofb_node_mask_i,
    fofb_dma_ok_o,
    fofb_rxlink_up_i,
    fofb_rxlink_partner_i
);

input              clk;
input              rst_n;

/* LocalLink Tx */
output [INTERFACE_WIDTH-1:0]        trn_td;
output [(INTERFACE_WIDTH/8)-1:0]    trn_trem_n;
output            trn_tsof_n;
output            trn_teof_n;
output            trn_tsrc_dsc_n;
output            trn_tsrc_rdy_n;
input             trn_tdst_dsc_n;
input             trn_tdst_rdy_n;
input  [5:0]      trn_tbuf_av;
output            trn_tstr_n;

/* LocalLink Rx */
input [INTERFACE_WIDTH-1:0]      trn_rd;
input [(INTERFACE_WIDTH/8)-1:0]       trn_rrem_n;

input             trn_rsof_n;
input             trn_reof_n;
input             trn_rsrc_rdy_n;
input             trn_rsrc_dsc_n;
output            trn_rdst_rdy_n;
input [6:0]       trn_rbar_hit_n;
output            trn_rnp_ok_n;
output            trn_rcpl_streaming_n;

`ifdef PCIE2_0
output [1:0]      pl_directed_link_change;
input  [5:0]      pl_ltssm_state; 
output [1:0]      pl_directed_link_width;
output            pl_directed_link_speed;
output            pl_directed_link_auton;
output            pl_upstream_preemph_src;
input  [1:0]      pl_sel_link_width;
input             pl_sel_link_rate;
input             pl_link_gen2_capable;
input             pl_link_partner_gen2_supported;
input  [2:0]      pl_initial_link_width;
input             pl_link_upcfg_capable;
input  [1:0]      pl_lane_reversal_mode;
`endif

output            req_compl_o;
output            compl_done_o;

output            cfg_interrupt_n;
input             cfg_interrupt_rdy_n;
output            cfg_interrupt_assert_n;
output [7:0]      cfg_interrupt_di;
input  [7:0]      cfg_interrupt_do;
input  [2:0]      cfg_interrupt_mmenable;
input             cfg_interrupt_msienable;
input [15:0]      cfg_completer_id;
input             cfg_ext_tag_en;
input             cfg_bus_mstr_enable;
input [5:0]       cfg_cap_max_lnk_width;
input [5:0]       cfg_neg_max_lnk_width;
input [2:0]       cfg_cap_max_payload_size;
input [2:0]       cfg_prg_max_payload_size;
input [2:0]       cfg_max_rd_req_size;
input             cfg_msi_enable;
input             cfg_rd_comp_bound;
input             cfg_phant_func_en;
input [1:0]       cfg_phant_func_supported;

output [31:0]     cpld_data_size_hwm;     // HWMark for Completion Data (DWs)
output [15:0]     cur_rd_count_hwm;       // HWMark for Read Count Allowed
output [31:0]     cpld_size;
output [15:0]     cur_mrd_count;

output [31:0]     fai_cfg_val_o;

output [9:0]      xy_buf_addr_o;
input  [63:0]     xy_buf_dat_i;
input             timeframe_end_rise_i;
input  [255:0]    fofb_node_mask_i;
output            fofb_dma_ok_o;
input             fofb_rxlink_up_i;
input  [9:0]      fofb_rxlink_partner_i;

wire   fofb_dma_ok_o = 1'b1;

/* Local wires */
wire  [3:0]       rd_be; 
wire  [31:0]      rd_data; 

wire  [10:0]      req_addr; 

wire  [7:0]       wr_be; 
wire  [31:0]      wr_data; 
wire              wr_en;
wire              wr_busy;

wire              req_compl;
wire              compl_done;

wire  [2:0]       req_tc;
wire              req_td; 
wire              req_ep; 
wire  [1:0]       req_attr; 
wire  [9:0]       req_len;
wire  [15:0]      req_rid;
wire  [7:0]       req_tag;
wire  [7:0]       req_be;

wire              mwr_start;
wire              mwr_int_dis_o; 
wire              mwr_done;
wire  [9:0]       mwr_len;
wire  [31:0]      mwr_addr;
wire  [15:0]      mwr_count;
wire  [15:0]      mwr_data;
wire  [2:0]       mwr_tlp_tc_o;  
wire              mwr_64b_en_o;
wire  [7:0]       mwr_up_addr;
wire              mwr_relaxed_order;
wire              mwr_nosnoop;

wire  [31:0]      cpld_size;
wire              cpl_streaming;
wire              trn_rnp_ok_n_o;
wire              trn_tstr_n_o;
wire              cfg_interrupt_legacyclr;

`ifdef PCIE2_0

wire [1:0]        pl_directed_link_change_o;
wire [1:0]        pl_directed_link_width_o;
wire              pl_directed_link_speed_o;
wire              pl_directed_link_auton_o;

reg  [5:0]        pl_ltssm_state_user; 
reg  [1:0]        pl_sel_link_width_user;
reg               pl_sel_link_rate_user;
reg               pl_link_gen2_capable_user;
reg               pl_link_partner_gen2_supported_user;
reg  [2:0]        pl_initial_link_width_user;
reg               pl_link_upcfg_capable_user;
reg  [1:0]        pl_lane_reversal_mode_user;
`endif

assign            trn_rnp_ok_n = trn_rnp_ok_n_o;
assign            trn_tstr_n = trn_tstr_n_o;
assign            trn_rcpl_streaming_n = ~cpl_streaming;


/*
 * Internal Resets
 */
wire              init_rst;
wire              wdma_rst;
wire              rwdma_rst = init_rst || wdma_rst;

wire [39:0]       wdma_addr;
wire              wdma_irq;
wire              mwr_stop;
wire [3:0]        wdma_status;
wire [15:0]       wdma_buf_ptr;
wire              next_wdma_valid;
wire              fofb_cc_timeout;

`ifdef PCIE2_0

/* Convert to user clock domain to ease timing for gen2 designs */
always @(posedge clk) begin
    if (!rst_n) begin
        pl_ltssm_state_user <= 6'b0; 
        pl_sel_link_width_user <= 2'b0;
        pl_sel_link_rate_user <= 1'b0;
        pl_link_gen2_capable_user <= 1'b0;
        pl_link_partner_gen2_supported_user <= 1'b0;
        pl_initial_link_width_user <= 3'b0;
        pl_link_upcfg_capable_user <= 1'b0;
        pl_lane_reversal_mode_user <= 2'b0;
    end 
    else begin
        pl_ltssm_state_user <= pl_ltssm_state; 
        pl_sel_link_width_user <= pl_sel_link_width;
        pl_sel_link_rate_user <= pl_sel_link_rate;
        pl_link_gen2_capable_user <= pl_link_gen2_capable;
        pl_link_partner_gen2_supported_user <= pl_link_partner_gen2_supported;
        pl_initial_link_width_user <= pl_initial_link_width;
        pl_link_upcfg_capable_user <= pl_link_upcfg_capable;
        pl_lane_reversal_mode_user <= pl_lane_reversal_mode;
    end
end

`endif

/*
 * ENDPOINT MEMORY :
 */
BMD_EP_MEM_ACCESS #(
    .INTERFACE_TYPE(INTERFACE_TYPE),
    .FPGA_FAMILY(FPGA_FAMILY)
)
EP_MEM (
    .clk                        ( clk                           ), // I
    .rst_n                      ( rst_n                         ), // I

    .cfg_cap_max_lnk_width      ( cfg_cap_max_lnk_width         ), // I [5:0]
    .cfg_neg_max_lnk_width      ( cfg_neg_max_lnk_width         ), // I [5:0]

    .cfg_cap_max_payload_size   ( cfg_cap_max_payload_size      ), // I [2:0]
    .cfg_prg_max_payload_size   ( cfg_prg_max_payload_size      ), // I [2:0]
    .cfg_max_rd_req_size        ( cfg_max_rd_req_size           ), // I [2:0]

    .addr_i                     ( req_addr[6:0]                 ), // I [10:0]
    /* Read Port */
    .rd_be_i                    ( rd_be                         ), // I [3:0]
    .rd_data_o                  ( rd_data                       ), // O [31:0]

    /* Write Port */
    .wr_be_i                    ( wr_be[3:0]                    ), // I [7:0]
    .wr_data_i                  ( wr_data                       ), // I [31:0]
    .wr_en_i                    ( wr_en                         ), // I
    .wr_busy_o                  ( wr_busy                       ), // O

    .init_rst_o                 ( init_rst                      ), // O

    .mwr_start_o                ( mwr_start                     ), // O
    .mwr_int_dis_o              ( mwr_int_dis_o                 ), // O
    .mwr_addr_o                 ( mwr_addr                      ), // O [31:0]
    .mwr_len_o                  ( mwr_len                       ), // O [31:0]
    .mwr_count_o                ( mwr_count                     ), // O [31:0]
    .mwr_data_o                 ( mwr_data                      ), // O [31:0]
    .mwr_tlp_tc_o               ( mwr_tlp_tc_o                  ), // O [2:0]
    .mwr_64b_en_o               ( mwr_64b_en_o                  ), // O
    .mwr_phant_func_dis1_o      (                               ), // O
    .mwr_up_addr_o              ( mwr_up_addr                   ), // O [7:0]
    .mwr_relaxed_order_o        ( mwr_relaxed_order             ), // O
    .mwr_nosnoop_o              ( mwr_nosnoop                   ), // O

`ifdef PCIE2_0
    .pl_directed_link_change    ( pl_directed_link_change       ),
    .pl_ltssm_state             ( pl_ltssm_state_user           ),
    .pl_directed_link_width     ( pl_directed_link_width        ),
    .pl_directed_link_speed     ( pl_directed_link_speed        ),
    .pl_directed_link_auton     ( pl_directed_link_auton        ),
    .pl_upstream_preemph_src    ( pl_upstream_preemph_src       ),
    .pl_sel_link_width          ( pl_sel_link_width_user        ),
    .pl_sel_link_rate           ( pl_sel_link_rate_user         ),
    .pl_link_gen2_capable       ( pl_link_gen2_capable_user     ),
    .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported_user ),
    .pl_initial_link_width      ( pl_initial_link_width_user    ),
    .pl_link_upcfg_capable      ( pl_link_upcfg_capable_user    ),
    .pl_lane_reversal_mode      ( pl_lane_reversal_mode_user    ),

    .pl_width_change_err        ( pl_width_change_err           ),
    .pl_speed_change_err        ( pl_speed_change_err           ),
    .clr_pl_width_change_err    ( clr_pl_width_change_err       ),
    .clr_pl_speed_change_err    ( clr_pl_speed_change_err       ),
    .clear_directed_speed_change( clear_directed_speed_change   ),
`endif
    .cpl_streaming_o            ( cpl_streaming                 ), // O
    .cfg_interrupt_di           ( cfg_interrupt_di              ), // O
    .cfg_interrupt_do           ( cfg_interrupt_do              ), // I
    .cfg_interrupt_mmenable     ( cfg_interrupt_mmenable        ), // I
    .cfg_interrupt_msienable    ( cfg_interrupt_msienable       ), // I
    .cfg_interrupt_legacyclr    ( cfg_interrupt_legacyclr       ), // O

    .trn_rnp_ok_n_o             ( trn_rnp_ok_n_o                ), // O
    .trn_tstr_n_o               ( trn_tstr_n_o                  ), // O

    .fai_cfg_val_o              ( fai_cfg_val_o                 ), // O

    .mwr_stop_o                 ( mwr_stop                      ),
    .wdma_status_i              ( wdma_status                   ),
    .wdma_buf_ptr_i             ( wdma_buf_ptr                  ),
    .next_wdma_valid_o          ( next_wdma_valid               ),
    .fofb_rxlink_up_i           ( fofb_rxlink_up_i              ),
    .fofb_rxlink_partner_i      ( fofb_rxlink_partner_i         ),
    .fofb_cc_timeout_i          ( fofb_cc_timeout               )
);


`ifdef PCIE2_0
BMD_GEN2 BMD_GEN2_I (
    .pl_directed_link_change    ( pl_directed_link_change       ),
    .pl_directed_link_width     ( pl_directed_link_width        ),
    .pl_directed_link_speed     ( pl_directed_link_speed        ),
    .pl_directed_link_auton     ( pl_directed_link_auton        ),
    .pl_sel_link_width          ( pl_sel_link_width_user        ),
    .pl_sel_link_rate           ( pl_sel_link_rate_user         ),
    .pl_ltssm_state             ( pl_ltssm_state_user           ),
    .clk                        ( clk                           ),
    .rst_n                      ( rst_n                         ),

    .pl_width_change_err        ( pl_width_change_err           ),
    .pl_speed_change_err        ( pl_speed_change_err           ),
    .clr_pl_width_change_err    ( clr_pl_width_change_err       ),
    .clr_pl_speed_change_err    ( clr_pl_speed_change_err       ),
    .clear_directed_speed_change( clear_directed_speed_change   )
);
`endif

/*
 * Local-Link Receive Controller :
 */
BMD_RX_ENGINE EP_RX (
    .clk                        ( clk                           ), // I
    .rst_n                      ( rst_n                         ), // I
    .init_rst_i                 ( rwdma_rst                     ), // I

    /* LocalLink Rx */
    .trn_rd                     ( trn_rd                        ), // I [63/31:0]
    .trn_rsof_n                 ( trn_rsof_n                    ), // I
    .trn_reof_n                 ( trn_reof_n                    ), // I
    .trn_rsrc_rdy_n             ( trn_rsrc_rdy_n                ), // I
    .trn_rdst_rdy_n             ( trn_rdst_rdy_n                ), // O

    /* Handshake with Tx engine */
    .req_compl_o                ( req_compl                     ), // O
    .compl_done_i               ( compl_done                    ), // I

    .addr_o                     ( req_addr                      ), // O [10:0]

    .req_tc_o                   ( req_tc                        ), // O [2:0]
    .req_td_o                   ( req_td                        ), // O
    .req_ep_o                   ( req_ep                        ), // O
    .req_attr_o                 ( req_attr                      ), // O [1:0]
    .req_len_o                  ( req_len                       ), // O [9:0]
    .req_rid_o                  ( req_rid                       ), // O [15:0]
    .req_tag_o                  ( req_tag                       ), // O [7:0]
    .req_be_o                   ( req_be                        ), // O [7:0]

    /* Memory Write Port */
    .wr_be_o                    ( wr_be                         ), // O [7:0]
    .wr_data_o                  ( wr_data                       ), // O [31:0]
    .wr_en_o                    ( wr_en                         ), // O
    .wr_busy_i                  ( wr_busy                       )  // I
);

/*
 * Local-Link Transmit Controller
 */
BMD_TX_ENGINE EP_TX (
    .clk                        (clk                            ), // I
    .rst_n                      (rst_n                          ), // I
    .init_rst_i                 ( rwdma_rst                     ), // I

    /* LocalLink Tx */
    .trn_td                     (trn_td                         ), // O [63/31:0]
    .trn_trem_n                 (trn_trem_n                     ), // O [7:0]
    .trn_tsof_n                 (trn_tsof_n                     ), // O
    .trn_teof_n                 (trn_teof_n                     ), // O
    .trn_tsrc_dsc_n             (trn_tsrc_dsc_n                 ), // O
    .trn_tsrc_rdy_n             (trn_tsrc_rdy_n                 ), // O
    .trn_tdst_dsc_n             (trn_tdst_dsc_n                 ), // I
    .trn_tdst_rdy_n             (trn_tdst_rdy_n                 ), // I
    .trn_tbuf_av                (trn_tbuf_av[3:0]               ), // I [3:0]

    /* Handshake with Rx engine */
    .req_compl_i                (req_compl                      ), // I
    .compl_done_o               (compl_done                     ), // 0

    .req_tc_i                   (req_tc                         ), // I [2:0]
    .req_td_i                   (req_td                         ), // I
    .req_ep_i                   (req_ep                         ), // I
    .req_attr_i                 (req_attr                       ), // I [1:0]
    .req_len_i                  (req_len                        ), // I [9:0]
    .req_rid_i                  (req_rid                        ), // I [15:0]
    .req_tag_i                  (req_tag                        ), // I [7:0]
    .req_be_i                   (req_be[3:0]                    ), // I [7:0]
    .req_addr_i                 (req_addr                       ), // I [10:0]

    /* Read Port */
    .rd_addr_o                  (                               ), // I [10:0]
    .rd_be_o                    ( rd_be                         ), // I [3:0]
    .rd_data_i                  ( rd_data                       ), // O [31:0]

    .mwr_start_i                ( wdma_start                    ), // I
    .mwr_int_dis_i              ( mwr_int_dis_o                 ), // I
    .mwr_done_o                 ( mwr_done                      ), // O
    .mwr_addr_i                 ( wdma_addr[31:0]               ), // I [31:0]
    .mwr_len_i                  ( mwr_len[9:0]                  ), // I [31:0]
    .mwr_count_i                ( mwr_count[15:0]               ), // I [31:0]
    .mwr_tlp_tc_i               ( mwr_tlp_tc_o                  ), // I [2:0]
    .mwr_64b_en_i               ( mwr_64b_en_o                  ), // I
    .mwr_phant_func_dis1_i      ( 1'b1                          ), // I
    .mwr_up_addr_i              ( wdma_addr[39:32]              ), // I [7:0]
    .mwr_lbe_i                  ( 4'hF                          ),
    .mwr_fbe_i                  ( 4'hF                          ),
    .mwr_relaxed_order_i        ( mwr_relaxed_order             ), // I
    .mwr_nosnoop_i              ( mwr_nosnoop                   ), // I

    .cfg_msi_enable_i           ( cfg_msi_enable                ), // I
    .cfg_interrupt_n_o          ( cfg_interrupt_n               ), // O
    .cfg_interrupt_assert_n_o   ( cfg_interrupt_assert_n        ), // O
    .cfg_interrupt_rdy_n_i      ( cfg_interrupt_rdy_n           ), // I
    .cfg_interrupt_legacyclr    ( cfg_interrupt_legacyclr       ), // I
    .completer_id_i             ( cfg_completer_id              ), // I [15:0]
    .cfg_ext_tag_en_i           ( cfg_ext_tag_en                ), // I
    .cfg_bus_mstr_enable_i      ( cfg_bus_mstr_enable           ), // I
    .cfg_phant_func_en_i        ( cfg_phant_func_en             ), // I
    .cfg_phant_func_supported_i ( cfg_phant_func_supported      ), // I [1:0]

    .xy_buf_addr_o              ( xy_buf_addr_o                 ),
    .xy_buf_dat_i               ( xy_buf_dat_i                  ),
    .wdma_irq_i                 ( wdma_irq                      )
);

assign req_compl_o  = req_compl;
assign compl_done_o = compl_done;

/*
 * Pcie Sniffer Application Control State Machine
 */
BMD_64_RWDMA_FSM BMD_64_RWDMA_FSM (
    .clk                        ( clk                           ),
    .rst_n                      ( rst_n                         ),
    .init_rst_i                 ( init_rst                      ),
    .wdma_rst_o                 ( wdma_rst                      ),

    .wdma_start_o               ( wdma_start                    ),
    .wdma_addr_o                ( wdma_addr                     ),
    .wdma_done_i                ( mwr_done                      ),
    .wdma_irq_o                 ( wdma_irq                      ),

    .next_wdma_addr_i           ( mwr_addr                      ),
    .next_wdma_up_addr_i        ( mwr_up_addr                   ),
    .next_wdma_valid_i          ( next_wdma_valid               ),
    .wdma_start_i               ( mwr_start                     ),
    .wdma_stop_i                ( mwr_stop                      ),
    .wdma_running_o             (                               ),
    .wdma_frame_len_i           ( mwr_data[15:0]                ),

    .timeframe_end_rise_i       ( timeframe_end_rise_i          ),

    .wdma_buf_ptr_o             ( wdma_buf_ptr                  ),
    .wdma_status_o              ( wdma_status                   ),
    .cc_timeout_o               ( fofb_cc_timeout               )
);

endmodule

