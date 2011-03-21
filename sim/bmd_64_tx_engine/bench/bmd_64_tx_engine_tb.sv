`timescale 1ns / 1ns

module bmd_64_tx_engine_tb;

logic               clk;
logic               rst_n;

logic  [63:0]       trn_td;
logic  [7:0]        trn_trem_n;
logic               trn_tsof_n;
logic               trn_teof_n;
logic               trn_tsrc_rdy_n;
logic               trn_tsrc_dsc_n;
logic               trn_tdst_rdy_n  = 1'b0;
logic               trn_tdst_dsc_n  = 1'b1;
logic [3:0]         trn_tbuf_av     = 3'b111;

logic               req_compl_i     = 1'b0;
logic               compl_done_o;

logic [2:0]         req_tc_i        = 0;
logic               req_td_i        = 0;
logic               req_ep_i        = 0;
logic [1:0]         req_attr_i      = 0;
logic [9:0]         req_len_i       = 0;
logic [15:0]        req_rid_i       = 0;
logic [7:0]         req_tag_i       = 0;
logic [3:0]         req_be_i        = 0;
logic [10:0]        req_addr_i      = 0;

logic  [6:0]        rd_addr_o;
logic  [3:0]        rd_be_o;
logic  [31:0]       rd_data_i       = 32'b0;

logic               init_rst_i;

logic               mwr_start_i;
logic               mwr_int_dis_i           = 1'b0;
logic  [9:0]        mwr_len_i;
logic  [3:0]        mwr_lbe_i               = 4'hF;
logic  [3:0]        mwr_fbe_i               = 4'hF;
logic  [31:0]       mwr_addr_i;
logic  [15:0]       mwr_count_i;
logic               mwr_done_o;
logic  [2:0]        mwr_tlp_tc_i            = 3'h0;
logic               mwr_64b_en_i;
logic               mwr_phant_func_dis1_i   = 1'b1;
logic  [7:0]        mwr_up_addr_i;
logic               mwr_relaxed_order_i     = 1'b0;
logic               mwr_nosnoop_i           = 1'b1;

logic               cfg_msi_enable_i         = 1'b1;
logic               cfg_interrupt_n_o;
logic               cfg_interrupt_assert_n_o;
logic               cfg_interrupt_rdy_n_i    = 1'b0;
logic               cfg_interrupt_legacyclr  = 1'b0;

logic [15:0]        completer_id_i           = 0;
logic               cfg_ext_tag_en_i         = 0;
logic               cfg_bus_mstr_enable_i    = 1'b1;

logic               cfg_phant_func_en_i      = 0;
logic [1:0]         cfg_phant_func_supported_i = 0;

logic  [9:0]        xy_buf_addr_o;
logic  [63:0]       xy_buf_dat_i;
logic               wdma_irq_i              = 1'b0;

// Instantiate the Unit Under Test (UUT)
BMD_TX_ENGINE uut (
    .*
);

parameter        offset = 0;
parameter        halfcycle = 4;

initial begin
    clk = 0;
    #(offset);
    forever #(halfcycle) clk = ~clk;
end


initial begin
    rst_n = 0;
    repeat(100) @(posedge clk);
    rst_n = 1;
end

logic               mem_init;
logic [ 8: 0]       mem_init_addr;
wire  [ 8: 0]       mem_addr = mem_init ? mem_init_addr : xy_buf_addr_o[ 8: 0];
logic [31: 0]       memx_din;
logic [31: 0]       memy_din;
logic               mem_we;
integer             i;

initial begin
    init_rst_i = 1'b0;
    mwr_start_i = 1'b0;
    mwr_addr_i = 32'h3800_0000;
    mwr_up_addr_i = 8'h00;
    mwr_len_i = 32;
    mwr_count_i = 16;
    mwr_64b_en_i = 1'b0;
    mem_init = 1'b1;
    mem_init_addr = 9'h0;
    repeat(10) @(posedge clk);
    // Initialise memory
    for (i = 0; i < 256; i = i + 1) begin
        mem_init_addr = i;
        memx_din = i;
        memy_din = i;
        mem_we = 1'b1;
        @(posedge clk);
        mem_we = 1'b0;
        @(posedge clk);
    end
    mem_init = 1'b0;
    repeat(100) @(posedge clk);
    // Initialise memory
    //
    init_rst_i = 1'b1;
    repeat(2) @(posedge clk);
    init_rst_i = 1'b0;
    repeat(100) @(posedge clk);
    mwr_start_i = 1'b1;
end

RAMB16_S36 x_sdpbram (
    .DO     ( xy_buf_dat_i[31: 0]   ),
    .DOP    (                       ),
    .ADDR   ( mem_addr              ),
    .CLK    ( clk                   ),
    .DI     ( memx_din              ),
    .DIP    ( 4'b0000               ),
    .EN     ( 1'b1                  ),
    .SSR    ( 1'b0                  ),
    .WE     ( mem_we                )
);

RAMB16_S36 y_sdpbram (
    .DO     ( xy_buf_dat_i[63:32]   ),
    .DOP    (                       ),
    .ADDR   ( mem_addr              ),
    .CLK    ( clk                   ),
    .DI     ( memy_din              ),
    .DIP    ( 4'b0000               ),
    .EN     ( 1'b1                  ),
    .SSR    ( 1'b0                  ),
    .WE     ( mem_we                )
);


endmodule

