//--------------------------------------------------------------------------------
//-- Filename: BMD_64_TX_ENGINE.v
//--
//-- Description: 64 bit Local-Link Transmit Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`define BMD_64_CPLD_FMT_TYPE   7'b10_01010
`define BMD_64_MWR_FMT_TYPE    7'b10_00000
`define BMD_64_MWR64_FMT_TYPE  7'b11_00000
`define BMD_64_MRD_FMT_TYPE    7'b00_00000
`define BMD_64_MRD64_FMT_TYPE  7'b01_00000

`define BMD_64_TX_RST_STATE    8'b00000001
`define BMD_64_TX_CPLD_QW1     8'b00000010
`define BMD_64_TX_CPLD_WIT     8'b00000100
`define BMD_64_TX_MWR_QW1      8'b00001000
`define BMD_64_TX_MWR64_QW1    8'b00010000
`define BMD_64_TX_MWR_QWN      8'b00100000
`define BMD_64_TX_MRD_QW1      8'b01000000
`define BMD_64_TX_MRD_QWN      8'b10000000

module BMD_TX_ENGINE (
    clk,
    rst_n,

    trn_td,
    trn_trem_n,
    trn_tsof_n,
    trn_teof_n,
    trn_tsrc_rdy_n,
    trn_tsrc_dsc_n,
    trn_tdst_rdy_n,
    trn_tdst_dsc_n,
    trn_tbuf_av,

    req_compl_i,
    compl_done_o,

    req_tc_i,
    req_td_i,
    req_ep_i,
    req_attr_i,
    req_len_i,
    req_rid_i,
    req_tag_i,
    req_be_i,
    req_addr_i,

    // BMD Read Access
    rd_addr_o,
    rd_be_o,
    rd_data_i,

    // Initiator Reset
    init_rst_i,

    // Write Initiator
    mwr_start_i,
    mwr_int_dis_i,
    mwr_len_i,
    mwr_lbe_i,
    mwr_fbe_i,
    mwr_addr_i,
    mwr_count_i,
    mwr_done_o,
    mwr_tlp_tc_i,
    mwr_64b_en_i,
    mwr_phant_func_dis1_i,
    mwr_up_addr_i,
    mwr_relaxed_order_i,
    mwr_nosnoop_i,

    cfg_msi_enable_i,
    cfg_interrupt_n_o,
    cfg_interrupt_assert_n_o,
    cfg_interrupt_rdy_n_i,
    cfg_interrupt_legacyclr,

    completer_id_i,
    cfg_ext_tag_en_i,
    cfg_bus_mstr_enable_i,
    cfg_phant_func_en_i,
    cfg_phant_func_supported_i,

    xy_buf_addr_o,
    xy_buf_dat_i,
    wdma_irq_i
);

input               clk;
input               rst_n;

output [63:0]       trn_td;
output [7:0]        trn_trem_n;
output              trn_tsof_n;
output              trn_teof_n;
output              trn_tsrc_rdy_n;
output              trn_tsrc_dsc_n;
input               trn_tdst_rdy_n;
input               trn_tdst_dsc_n;
input [3:0]         trn_tbuf_av;

input               req_compl_i;
output              compl_done_o;

input [2:0]         req_tc_i;
input               req_td_i;
input               req_ep_i;
input [1:0]         req_attr_i;
input [9:0]         req_len_i;
input [15:0]        req_rid_i;
input [7:0]         req_tag_i;
input [3:0]         req_be_i;
input [10:0]        req_addr_i;

output [6:0]        rd_addr_o;
output [3:0]        rd_be_o;
input  [31:0]       rd_data_i;

input               init_rst_i;

input               mwr_start_i;
input               mwr_int_dis_i;
input  [9:0]        mwr_len_i;
input  [3:0]        mwr_lbe_i;
input  [3:0]        mwr_fbe_i;
input  [31:0]       mwr_addr_i;
input  [15:0]       mwr_count_i;
output              mwr_done_o;
input  [2:0]        mwr_tlp_tc_i;
input               mwr_64b_en_i;
input               mwr_phant_func_dis1_i;
input  [7:0]        mwr_up_addr_i;
input               mwr_relaxed_order_i;
input               mwr_nosnoop_i;

input               cfg_msi_enable_i;
output              cfg_interrupt_n_o;
output              cfg_interrupt_assert_n_o;
input               cfg_interrupt_rdy_n_i;
input               cfg_interrupt_legacyclr;

input [15:0]        completer_id_i;
input               cfg_ext_tag_en_i;
input               cfg_bus_mstr_enable_i;

input               cfg_phant_func_en_i;
input [1:0]         cfg_phant_func_supported_i;

output [9:0]        xy_buf_addr_o;
input  [63:0]       xy_buf_dat_i;
input               wdma_irq_i;


// Local registers
reg [63:0]          trn_td;
reg [7:0]           trn_trem_n;
reg                 trn_tsof_n;
reg                 trn_teof_n;
reg                 trn_tsrc_rdy_n;
reg                 trn_tsrc_dsc_n;

reg [11:0]          byte_count;
reg [06:0]          lower_addr;

reg                 req_compl_q;
reg [7:0]           bmd_64_tx_state;
reg                 compl_done_o;
reg                 mwr_done_o;
reg [15:0]          cur_wr_count;
reg [9:0]           cur_mwr_dw_count;
reg [12:0]          mwr_len_byte;
reg [31:0]          pmwr_addr;
reg [31:0]          tmwr_addr;
reg [15:0]          rmwr_count;
reg [63:0]          xy_buf_dat_lt;


reg [5:0]           delay_cntr;

// Local wires
wire                cfg_bm_en = cfg_bus_mstr_enable_i;
wire [31:0]         mwr_addr  = mwr_addr_i;

wire [63:0]         xy_buf_dat    = {xy_buf_dat_i[07:00],
                                     xy_buf_dat_i[15:08],
                                     xy_buf_dat_i[23:16],
                                     xy_buf_dat_i[31:24],
                                     xy_buf_dat_i[39:32],
                                     xy_buf_dat_i[47:40],
                                     xy_buf_dat_i[55:48],
                                     xy_buf_dat_i[63:56]};

wire [63:0]         trn_data = (mwr_64b_en_i) ? xy_buf_dat_lt : {xy_buf_dat_lt[31:0], xy_buf_dat[63:32]};

wire  [2:0]         mwr_func_num = (!mwr_phant_func_dis1_i && cfg_phant_func_en_i) ?
    ((cfg_phant_func_supported_i == 2'b00) ? 3'b000 :
    (cfg_phant_func_supported_i == 2'b01) ? {cur_wr_count[8], 2'b00} :
    (cfg_phant_func_supported_i == 2'b10) ? {cur_wr_count[9:8], 1'b0} :
    (cfg_phant_func_supported_i == 2'b11) ? {cur_wr_count[10:8]} : 3'b000) : 3'b000;

/*
 * Present address and byte enable to memory module
 */
assign rd_addr_o = req_addr_i[10:2];
assign rd_be_o =   req_be_i[3:0];

/*
 * Calculate byte count based on byte enable
 */
always @ (rd_be_o) begin
    casex (rd_be_o[3:0])
        4'b1xx1 : byte_count = 12'h004;
        4'b01x1 : byte_count = 12'h003;
        4'b1x10 : byte_count = 12'h003;
        4'b0011 : byte_count = 12'h002;
        4'b0110 : byte_count = 12'h002;
        4'b1100 : byte_count = 12'h002;
        4'b0001 : byte_count = 12'h001;
        4'b0010 : byte_count = 12'h001;
        4'b0100 : byte_count = 12'h001;
        4'b1000 : byte_count = 12'h001;
        4'b0000 : byte_count = 12'h001;
    endcase
end

/*
 * Calculate lower address based on  byte enable
 */
always @(rd_be_o or req_addr_i) 
begin
    casex (rd_be_o[3:0])
        4'b0000 : lower_addr = {req_addr_i[4:0], 2'b00};
        4'bxxx1 : lower_addr = {req_addr_i[4:0], 2'b00};
        4'bxx10 : lower_addr = {req_addr_i[4:0], 2'b01};
        4'bx100 : lower_addr = {req_addr_i[4:0], 2'b10};
        4'b1000 : lower_addr = {req_addr_i[4:0], 2'b11};
    endcase
end

always @(posedge clk) 
begin
    if (!rst_n ) begin
        req_compl_q <= 1'b0;
    end
    else begin 
        req_compl_q <= req_compl_i;
    end
end

/*
 *  Interrupt Controller
 */

BMD_INTR_CTRL BMD_INTR_CTRL  (
    .clk                        ( clk                           ), // I
    .rst_n                      ( rst_n                         ), // I

    .init_rst_i                 ( init_rst_i                    ), // I

    .mrd_done_i                 ( 1'b0                          ), // I
    .mwr_done_i                 ( wdma_irq_i & !mwr_int_dis_i   ), // I

    .msi_on                     ( cfg_msi_enable_i              ), // I

    .cfg_interrupt_rdy_n_i      ( cfg_interrupt_rdy_n_i         ), // I
    .cfg_interrupt_assert_n_o   ( cfg_interrupt_assert_n_o      ), // O
    .cfg_interrupt_n_o          ( cfg_interrupt_n_o             ), // O
    .cfg_interrupt_legacyclr    ( cfg_interrupt_legacyclr       )  // I
);


/*
 *  Tx State Machine 
 */

always @ ( posedge clk ) begin

    if (!rst_n ) begin
        trn_tsof_n          <= 1'b1;
        trn_teof_n          <= 1'b1;
        trn_tsrc_rdy_n      <= 1'b1;
        trn_tsrc_dsc_n      <= 1'b1;
        trn_td              <= 64'b0;
        trn_trem_n          <= 8'b0;
        cur_mwr_dw_count    <= 10'b0;
        compl_done_o        <= 1'b0;
        mwr_done_o          <= 1'b0;
        cur_wr_count        <= 16'b0;
        mwr_len_byte        <= 13'b0;
        pmwr_addr           <= 32'b0;
        rmwr_count          <= 16'b0;
        bmd_64_tx_state     <= `BMD_64_TX_RST_STATE;
        delay_cntr          <= 6'h0;

    end
    else begin
        if (init_rst_i ) begin
            trn_tsof_n          <= 1'b1;
            trn_teof_n          <= 1'b1;
            trn_tsrc_rdy_n      <= 1'b1;
            trn_tsrc_dsc_n      <= 1'b1;
            trn_td              <= 64'b0;
            trn_trem_n          <= 8'b0;
            cur_mwr_dw_count    <= 10'b0;
            compl_done_o        <= 1'b0;
            mwr_done_o          <= 1'b0;
            cur_wr_count        <= 16'b0;
            mwr_len_byte        <= 13'b0;
            pmwr_addr           <= 32'b0;
            rmwr_count          <= 16'b0;
            bmd_64_tx_state     <= `BMD_64_TX_RST_STATE;
            delay_cntr          <= 6'h0;
        end

        mwr_len_byte        <= 4 * mwr_len_i[9:0];
        rmwr_count          <= mwr_count_i[15:0];

        case ( bmd_64_tx_state )

            `BMD_64_TX_RST_STATE : begin
                delay_cntr         <= 6'h0;
                compl_done_o       <= 1'b0;

                // PIO read completions always get highest priority
                if (req_compl_q && !compl_done_o && !trn_tdst_rdy_n && trn_tdst_dsc_n) begin
                    trn_tsof_n       <= 1'b0;
                    trn_teof_n       <= 1'b1;
                    trn_tsrc_rdy_n   <= 1'b0;
                    trn_td           <= { {1'b0},
                                      `BMD_64_CPLD_FMT_TYPE,
                                      {1'b0},
                                      req_tc_i,
                                      {4'b0},
                                      req_td_i,
                                      req_ep_i,
                                      req_attr_i,
                                      {2'b0},
                                      req_len_i,
                                      completer_id_i,
                                      {3'b0},
                                      {1'b0},
                                      byte_count };
                    trn_trem_n        <= 8'b0;

                    bmd_64_tx_state   <= `BMD_64_TX_CPLD_QW1;

                end
                else if (mwr_start_i && !mwr_done_o && !trn_tdst_rdy_n && trn_tdst_dsc_n && cfg_bm_en) begin
                    trn_tsof_n       <= 1'b0;
                    trn_teof_n       <= 1'b1;
                    trn_tsrc_rdy_n   <= 1'b0;
                    trn_td           <= { {1'b0}, 
                                      {mwr_64b_en_i ? `BMD_64_MWR64_FMT_TYPE : `BMD_64_MWR_FMT_TYPE},
                                      {1'b0},
                                      mwr_tlp_tc_i,
                                      {4'b0},
                                      1'b0,
                                      1'b0,
                                      {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00,
                                      {2'b0},
                                      mwr_len_i[9:0],
                                      {completer_id_i[15:3], mwr_func_num},
                                      cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
                                      (mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
                                      mwr_fbe_i};
                    trn_trem_n        <= 8'b0;
                    cur_mwr_dw_count  <= mwr_len_i[9:0];

                    bmd_64_tx_state   <= `BMD_64_TX_MWR64_QW1;

                    if (mwr_64b_en_i)
                      bmd_64_tx_state   <= `BMD_64_TX_MWR64_QW1;
                    else
                      bmd_64_tx_state   <= `BMD_64_TX_MWR_QW1;
                end
                else begin
                    if(!trn_tdst_rdy_n) begin
                        trn_tsof_n        <= 1'b1;
                        trn_teof_n        <= 1'b1;
                        trn_tsrc_rdy_n    <= 1'b1;
                        trn_tsrc_dsc_n    <= 1'b1;
                        trn_td            <= 64'b0;
                        trn_trem_n        <= 8'b0;
                    end

                    bmd_64_tx_state   <= `BMD_64_TX_RST_STATE;
                end
            end

            `BMD_64_TX_CPLD_QW1 : begin

                if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin
                    trn_tsof_n       <= 1'b1;
                    trn_teof_n       <= 1'b0;
                    trn_tsrc_rdy_n   <= 1'b0;
                    trn_td           <= { req_rid_i,
                                          req_tag_i,
                                          {1'b0},
                                          lower_addr,
                                          rd_data_i };
                    trn_trem_n       <= 8'h00;
                    compl_done_o     <= 1'b1;

                    bmd_64_tx_state  <= `BMD_64_TX_CPLD_WIT;
                end
                else if (!trn_tdst_dsc_n) begin
                    trn_tsrc_dsc_n   <= 1'b0;
                    bmd_64_tx_state  <= `BMD_64_TX_CPLD_WIT;
                end
                else
                    bmd_64_tx_state  <= `BMD_64_TX_CPLD_QW1;
            end

            `BMD_64_TX_CPLD_WIT : begin
                if ( (!trn_tdst_rdy_n) || (!trn_tdst_dsc_n) ) begin
                    trn_tsof_n       <= 1'b1;
                    trn_teof_n       <= 1'b1;
                    trn_tsrc_rdy_n   <= 1'b1;
                    trn_tsrc_dsc_n   <= 1'b1;

                    bmd_64_tx_state  <= `BMD_64_TX_RST_STATE;
                end else
                    bmd_64_tx_state  <= `BMD_64_TX_CPLD_WIT;
            end

            `BMD_64_TX_MWR_QW1 : begin
                if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin
                    trn_tsof_n       <= 1'b1;
                    trn_tsrc_rdy_n   <= 1'b0;

                    if (cur_wr_count == 0)
                        tmwr_addr   = mwr_addr;
                    else
                        tmwr_addr   = pmwr_addr + mwr_len_byte;

                    trn_td          <= {{tmwr_addr[31:2], 2'b00}, xy_buf_dat[63:32]};
                    pmwr_addr       <= tmwr_addr;
                    cur_wr_count    <= cur_wr_count + 1'b1;

                    if (cur_mwr_dw_count == 1'h1) begin
                        trn_teof_n       <= 1'b0;
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1'h1;
                        trn_trem_n       <= 8'h00;

                        if (cur_wr_count == (rmwr_count - 1'b1))  begin
                            cur_wr_count <= 0;
                            mwr_done_o   <= 1'b1;
                        end

                        bmd_64_tx_state  <= `BMD_64_TX_RST_STATE;
                    end
                    else begin
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1'h1;
                        trn_trem_n       <= 8'hFF;
                        bmd_64_tx_state  <= `BMD_64_TX_MWR_QWN;
                    end
                end
                else if (!trn_tdst_dsc_n) begin
                    bmd_64_tx_state    <= `BMD_64_TX_RST_STATE;
                    trn_tsrc_dsc_n     <= 1'b0;
                end
                else
                    bmd_64_tx_state    <= `BMD_64_TX_MWR_QW1;
            end

            `BMD_64_TX_MWR64_QW1 : begin
                if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin
                    trn_tsof_n      <= 1'b1;
                    trn_tsrc_rdy_n  <= 1'b0;

                    if (cur_wr_count == 0)
                        tmwr_addr   = mwr_addr;
                    else
                        tmwr_addr   = {pmwr_addr[31:24], pmwr_addr[23:0] + mwr_len_byte};
                    trn_td          <= {{24'b0},mwr_up_addr_i,tmwr_addr[31:2],{2'b0}};
                    pmwr_addr       <= tmwr_addr;

                    cur_wr_count    <= cur_wr_count + 1'b1;
                    bmd_64_tx_state <= `BMD_64_TX_MWR_QWN;

                end
                else if (!trn_tdst_dsc_n) begin
                    bmd_64_tx_state    <= `BMD_64_TX_RST_STATE;
                    trn_tsrc_dsc_n     <= 1'b0;
                end else
                    bmd_64_tx_state    <= `BMD_64_TX_MWR64_QW1;
            end

            `BMD_64_TX_MWR_QWN : begin
                if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin
                    trn_tsrc_rdy_n   <= 1'b0;

                    if (cur_mwr_dw_count == 1'h1) begin
                        trn_td           <= {trn_data[63:32], 32'hd0_da_d0_da};
                        trn_trem_n       <= 8'h0F;
                        trn_teof_n       <= 1'b0;
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1'h1; 
                        bmd_64_tx_state  <= `BMD_64_TX_RST_STATE;

                        if (cur_wr_count == rmwr_count)  begin
                            cur_wr_count <= 0; 
                            mwr_done_o   <= 1'b1;
                        end
                    end
                    else if (cur_mwr_dw_count == 2'h2) begin
                        trn_td           <= trn_data;
                        trn_trem_n       <= 8'h00;
                        trn_teof_n       <= 1'b0;
                        cur_mwr_dw_count <= cur_mwr_dw_count - 2'h2;
                        bmd_64_tx_state  <= `BMD_64_TX_RST_STATE;

                        if (cur_wr_count == rmwr_count)  begin
                            cur_wr_count <= 0;
                            mwr_done_o   <= 1'b1;
                        end
                    end
                    else begin
                        trn_td           <= trn_data;
                        trn_trem_n       <= 8'hFF;
                        cur_mwr_dw_count <= cur_mwr_dw_count - 2'h2;
                        bmd_64_tx_state  <= `BMD_64_TX_MWR_QWN;
                    end
                end
                else if (!trn_tdst_dsc_n) begin
                    bmd_64_tx_state     <= `BMD_64_TX_RST_STATE;
                    trn_tsrc_dsc_n      <= 1'b0;
                end
                else begin
                    bmd_64_tx_state     <= `BMD_64_TX_MWR_QWN;
                end
            end

            endcase
        end
    end

/*
 * Implement a FIFO-like read interface to x&y position buffers
 * This is MAGIC!!!
 */

/* Accept only first compl_done input */
wire compl_done_bypass = (cur_wr_count==0) ? !compl_done_o : 1'b1;

wire pop_data =
trn_teof_n  &&
(
(!(req_compl_q && compl_done_bypass && !trn_tdst_rdy_n && trn_tdst_dsc_n) &&  (mwr_start_i && !mwr_done_o && !trn_tdst_rdy_n && trn_tdst_dsc_n && cfg_bm_en) && (bmd_64_tx_state == `BMD_64_TX_RST_STATE)) ||
(!trn_tdst_rdy_n && trn_tdst_dsc_n && (bmd_64_tx_state == `BMD_64_TX_MWR_QW1)) ||
(!trn_tdst_rdy_n && trn_tdst_dsc_n && (bmd_64_tx_state == `BMD_64_TX_MWR64_QW1)) ||
(!trn_tdst_rdy_n && trn_tdst_dsc_n && (cur_mwr_dw_count != 1'h1 && cur_mwr_dw_count != 2'h2) && (bmd_64_tx_state == `BMD_64_TX_MWR_QWN))
);

reg  [7:0]      xy_buf_addr;
reg  [7:0]      xy_buf_addr_next;

assign xy_buf_addr_o = pop_data ? {2'b0, xy_buf_addr_next} : {2'b0, xy_buf_addr};

always @ (posedge clk) 
begin
    if (!rst_n ) begin
        xy_buf_addr <= 8'hFF;
        xy_buf_addr_next <= 8'h0;
    end
    else begin
        if (init_rst_i ) begin
            xy_buf_addr <= 8'hFF;
            xy_buf_addr_next <= 8'h0;
        end

        if (pop_data) begin
            xy_buf_addr <= xy_buf_addr_next;
            xy_buf_addr_next <= xy_buf_addr_next + 1;
        end
    end
end

always @ (posedge clk)
begin
    if (pop_data)
        xy_buf_dat_lt = xy_buf_dat;
end

/*
 * Debug Logic
 */
/*
reg cscope_trig;

always @ (posedge clk)
begin
    if (trn_td[63:32] == (mwr_addr_i + mwr_len_byte)) begin
        if (trn_td[31:0] != 32'h10_00_00_00)
            cscope_trig = 1'b1;
        else
            cscope_trig = 1'b0;
    end
end
*/

/*
 * Chipscope Interface
 */
/*
wire [35:0]     control0;
wire [255:0]    data;
wire [7:0]      trig;

icon i_icon (
    .control0                   ( control0                  )
);

ila i_ila (
    .control                    ( control0                  ),
    .clk                        ( clk                       ),
    .data                       ( data                      ),
    .trig0                      ( trig                      )
);

assign trig[0] = init_rst_i;
assign trig[1] = mwr_start_i;
assign trig[2] = trn_tdst_rdy_n;
assign trig[3] = trn_tsrc_rdy_n;
assign trig[4] = trn_tsof_n;
assign trig[5] = cscope_trig;
assign trig[7:6] = 0;

assign data[63:0]   = trn_td;
assign data[71:64]  = trn_trem_n;
assign data[72]     = trn_tsof_n;
assign data[73]     = trn_teof_n;
assign data[74]     = trn_tsrc_rdy_n;
assign data[75]     = trn_tsrc_dsc_n;
assign data[76]     = trn_tdst_rdy_n;
assign data[77]     = trn_tdst_dsc_n;
assign data[78]     = mwr_start_i;
assign data[79]     = mwr_done_o;
assign data[80]     = cfg_bm_en;
assign data[96:81]  = rmwr_count;
assign data[106:97] = cur_mwr_dw_count;
assign data[122:107] = cur_wr_count;
assign data[126:123] = trn_tbuf_av;
assign data[135:127] = bmd_64_tx_state;
assign data[136]     = mwr_64b_en_i;
assign data[146:137] = xy_buf_addr_o;
assign data[210:147] = xy_buf_dat_i;
assign data[211] = cscope_trig;
assign data[212] = req_compl_q;
assign data[213] = compl_done_o;
assign data[220:214] = rd_addr_o;
assign data[252:221] = rd_data_i;
assign data[253]     = compl_done_bypass;
*/

endmodule // BMD_64_TX_ENGINE

