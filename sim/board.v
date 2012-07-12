//------------------------------------------------------------------------------
//
// Filename: board.v
//
// Description:  Top level testbench
//
//------------------------------------------------------------------------------

`include "board_common.v"

module board;

integer             i;

/*
 * System reset
 */
reg                cor_sys_reset_n;

/*
 * System clock
 */
wire               dsport_sys_clk_p;
wire               dsport_sys_clk_n;
wire               cor_sys_clk_p;
wire               cor_sys_clk_n;

/*
 * PCI-Express facric interface
 */
wire  [(4 - 1):0]  cor_pci_exp_txn;
wire  [(4 - 1):0]  cor_pci_exp_txp;
wire  [(4 - 1):0]  cor_pci_exp_rxn;
wire  [(4 - 1):0]  cor_pci_exp_rxp;

/*
 * Communication Controller interface
 */
wire               cor_gtp_clk_p;
wire               cor_gtp_clk_n;
wire               cor_gtp_clk2x_p;
wire               cor_gtp_clk2x_n;
wire  [(2 - 1):0]  cor_sfp_txn;
wire  [(2 - 1):0]  cor_sfp_txp;
wire  [(2 - 1):0]  cor_sfp_rxn;
wire  [(2 - 1):0]  cor_sfp_rxp;

/*
 * PCI-Express End Point Instance
 */
pcie_cc_top # (
    .SIM_GTPRESET_SPEEDUP   ( 1                     ),
    .LANE_COUNT             ( 2                     )
//    .TX_IDLE_NUM            ( 6                     ),
//    .RX_IDLE_NUM            ( 3                     ),
//    .SEND_ID_NUM            ( 4                     )
)
pcie_cc_top(
    // SYS Inteface
    .sys_clk_p              ( cor_sys_clk_p         ),
    .sys_clk_n              ( cor_sys_clk_n         ),
    .sys_reset_n            ( cor_sys_reset_n       ),

    // ICS Clock Synth 2 Interface
    .mgt_clksel             (                       ),
    .ics_clk                (                       ),
    .strobe                 (                       ),
    .pload                  (                       ),
    .sdata                  (                       ),
    .sclock                 (                       ),

    // PCI-Express Interface
    .pci_exp_txn            ( cor_pci_exp_txn       ),
    .pci_exp_txp            ( cor_pci_exp_txp       ),
    .pci_exp_rxn            ( cor_pci_exp_rxn       ),
    .pci_exp_rxp            ( cor_pci_exp_rxp       ),

    // GTP Interface
    .gtp_clk_p              ( cor_gtp_clk_p         ),
    .gtp_clk_n              ( cor_gtp_clk_n         ),
    .sfp_txp                ( cor_sfp_txp           ),
    .sfp_txn                ( cor_sfp_txn           ),
    .sfp_rxp                ( cor_sfp_rxp           ),
    .sfp_rxn                ( cor_sfp_rxn           )
);
//defparam pcie_cc_top.ep.\BU2/U0/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[0].GT_i .SIM_GTPRESET_SPEEDUP = 1;
//defparam pcie_cc_top.ep.\BU2/U0/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[2].GT_i .SIM_GTPRESET_SPEEDUP = 1;

/*
 * FOFB CC Downstream Port Model Instanse
 */
reg                 cor_gtp_reset;
reg                 timeframe_start;

wire                rxn;
wire                rxp;
wire                txn;
wire                txp;

assign              cor_sfp_rxp[0] = txp;
assign              cor_sfp_rxn[0] = txn;
assign              cor_sfp_rxp[1] = txp;
assign              cor_sfp_rxn[1] = txn;

assign              rxp = cor_sfp_txp[0];
assign              rxn = cor_sfp_txn[0];

fofb_cc_top_tester # (
//    .TX_IDLE_NUM            ( 6                     ),
//    .RX_IDLE_NUM            ( 3                     ),
//    .SEND_ID_NUM            ( 4                     ),
    .TEST_DURATION          ( 3                     )
)
fofb_cc_top_tester (
    .refclk_i               ( cor_gtp_clk_p         ),
    .txusrclk_i             ( cor_gtp_clk2x_p       ),
    .txusrclk2_i            ( cor_gtp_clk_p         ),
    .mgtreset_i             ( cor_gtp_reset         ),
    .adcclk_i               (                       ),

    .fai_cfg_a_i            ( 11'h0                 ),
    .fai_cfg_do_i           ( 32'h0                 ),
    .fai_cfg_di_o           (                       ),
    .fai_cfg_we_i           ( 1'b0                  ),
    .fai_cfg_clk_i          ( 1'b0                  ),
    .fai_cfg_val_o          (                       ),

    .fai_fa_block_start_o   (                       ),
    .fai_fa_data_valid_o    (                       ),
    .fai_fa_d_o             (                       ),

    .rxn_i                  ( rxn                   ),
    .rxp_i                  ( rxp                   ),
    .txn_o                  ( txn                   ),
    .txp_o                  ( txp                   )
);


/*
 * PCI-E Downstream Port Model Instance
 */
xilinx_pci_exp_4_lane_downstream_port xilinx_pci_exp_4_lane_downstream_port (

        // SYS Inteface
        .sys_clk_p(dsport_sys_clk_p),
        .sys_clk_n(dsport_sys_clk_n),
        .sys_reset_n(cor_sys_reset_n),

        // PCI-Express Interface
        .pci_exp_txn(cor_pci_exp_rxn),
        .pci_exp_txp(cor_pci_exp_rxp),
        .pci_exp_rxn(cor_pci_exp_txn),
        .pci_exp_rxp(cor_pci_exp_txp)

/*
// The following muxing logic is a work-around due to the fact that the GTP Transceiver models output X values which propagate to the downstream port which in turn causes prohibitively long simulation times for link up. Refer to CR# 442695.
        .pci_exp_rxn({(((cor_pci_exp_txn[3] === 1'bx) && (cor_pci_exp_txp[3] === 1'bx)) ? 1'b1 : cor_pci_exp_txn[3]), (((cor_pci_exp_txn[2] === 1'bx) && (cor_pci_exp_txp[2] === 1'bx)) ? 1'b1 : cor_pci_exp_txn[2]), (((cor_pci_exp_txn[1] === 1'bx) && (cor_pci_exp_txp[1] === 1'bx)) ? 1'b1 : cor_pci_exp_txn[1]), (((cor_pci_exp_txn[0] === 1'bx) && (cor_pci_exp_txp[0] === 1'bx)) ? 1'b1 : cor_pci_exp_txn[0])}),
        .pci_exp_rxp({(((cor_pci_exp_txn[3] === 1'bx) && (cor_pci_exp_txp[3] === 1'bx)) ? 1'b1 : cor_pci_exp_txp[3]), (((cor_pci_exp_txn[2] === 1'bx) && (cor_pci_exp_txp[2] === 1'bx)) ? 1'b1 : cor_pci_exp_txp[2]), (((cor_pci_exp_txn[1] === 1'bx) && (cor_pci_exp_txp[1] === 1'bx)) ? 1'b1 : cor_pci_exp_txp[1]), (((cor_pci_exp_txn[0] === 1'bx) && (cor_pci_exp_txp[0] === 1'bx)) ? 1'b1 : cor_pci_exp_txp[0])})
*/

);

/*
 * Clock Interfaces
 */
sys_clk_gen_ds SYS_CLK_GEN_DSPORT (
    .sys_clk_p      ( dsport_sys_clk_p      ),
    .sys_clk_n      ( dsport_sys_clk_n      )
);
defparam SYS_CLK_GEN_DSPORT.halfcycle = 2000;   // 250 MHz
defparam SYS_CLK_GEN_DSPORT.offset = 0;

sys_clk_gen_ds SYS_CLK_GEN_COR (
    .sys_clk_p      ( cor_sys_clk_p         ),
    .sys_clk_n      ( cor_sys_clk_n         )
);
defparam SYS_CLK_GEN_COR.halfcycle = 5000;      // 100 MHz
defparam SYS_CLK_GEN_COR.offset = 0;

sys_clk_gen_ds SYS_CLK_GEN_CC (
    .sys_clk_p      ( cor_gtp_clk_p         ),
    .sys_clk_n      ( cor_gtp_clk_n         )
);
defparam SYS_CLK_GEN_CC.halfcycle = 4700;   // 106.25 MHz
defparam SYS_CLK_GEN_CC.offset = 0;

sys_clk_gen_ds SYS_CLK_GEN_CC_2X (
    .sys_clk_p      ( cor_gtp_clk2x_p       ),
    .sys_clk_n      ( cor_gtp_clk2x_n       )
);
defparam SYS_CLK_GEN_CC.halfcycle = 2350;   // 106.25x2 MHz
defparam SYS_CLK_GEN_CC.offset = 0;

initial begin
    if ($test$plusargs ("dump_all")) begin
        // VCD dump
        `ifdef BOARDx01
            $dumpfile("boardx01.vcd");
        `endif
        `ifdef BOARDx04
            $dumpfile("boardx04.vcd");
        `endif
        `ifdef BOARDx08
            $dumpfile("boardx08.vcd");
        `endif

        $dumpvars(0, board);
    end

    $display("[%t] : System Reset Asserted...", $realtime);
    cor_sys_reset_n = 1'b0;
    for (i = 0; i < 50; i = i + 1) begin
        @(posedge cor_sys_clk_p);
    end
    $display("[%t] : System Reset De-asserted...", $realtime);
    cor_sys_reset_n = 1'b1;

end

initial begin
    $display("[%t] : GTP Reset Asserted...", $realtime);
    cor_gtp_reset = 1'b1;
    for (i = 0; i < 10000; i = i + 1) begin
        @(posedge cor_gtp_clk_p);
    end
    $display("[%t] : GTP Reset De-asserted...", $realtime);
    cor_gtp_reset = 1'b0;
end

endmodule // BOARD


