`timescale 1ns / 1ps

module bmd_tx_engine_tb;

// Inputs
reg clk;
reg rst_n;
reg trn_tdst_rdy_n;
reg trn_tdst_dsc_n;
reg [3:0] trn_tbuf_av;
reg req_compl_i;
reg [2:0] req_tc_i;
reg req_td_i;
reg req_ep_i;
reg [1:0] req_attr_i;
reg [9:0] req_len_i;
reg [15:0] req_rid_i;
reg [7:0] req_tag_i;
reg [3:0] req_be_i;
reg [10:0] req_addr_i;
reg [31:0] rd_data_i;
reg init_rst_i;
reg mwr_start_i;
reg mwr_int_dis_i;
reg [9:0] mwr_len_i;
reg [7:0] mwr_tag_i;
reg [3:0] mwr_lbe_i;
reg [3:0] mwr_fbe_i;
reg [31:0] mwr_addr_i;
reg [15:0] mwr_count_i;
reg [2:0] mwr_tlp_tc_i;
reg mwr_64b_en_i;
reg mwr_phant_func_dis1_i;
reg [7:0] mwr_up_addr_i;
reg mwr_relaxed_order_i;
reg mwr_nosnoop_i;
reg [7:0] mwr_wrr_cnt_i;
reg cfg_msi_enable_i;
reg cfg_interrupt_rdy_n_i;
reg cfg_interrupt_legacyclr;
reg [15:0] completer_id_i;
reg cfg_ext_tag_en_i;
reg cfg_bus_mstr_enable_i;
reg cfg_phant_func_en_i;
reg [1:0] cfg_phant_func_supported_i;
reg wdma_irq_i;
reg timeframe_end_i;
reg [255:0] fofb_node_buffer = 0;

wire[63:0] xy_buf_dat_i;

// Outputs
wire [63:0] trn_td;
wire [7:0] trn_trem_n;
wire trn_tsof_n;
wire trn_teof_n;
wire trn_tsrc_rdy_n;
wire trn_tsrc_dsc_n;
wire compl_done_o;
wire [6:0] rd_addr_o;
wire [3:0] rd_be_o;
wire mwr_done_o;
wire cfg_interrupt_n_o;
wire cfg_interrupt_assert_n_o;
wire [9:0] xy_buf_addr_o;
integer i;

parameter        offset = 0;
parameter        halfcycle = 5;

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

// Instantiate the Unit Under Test (UUT)
BMD_TX_ENGINE uut (
    .clk(clk), 
    .rst_n(rst_n), 
    .trn_td(trn_td), 
    .trn_trem_n(trn_trem_n), 
    .trn_tsof_n(trn_tsof_n), 
    .trn_teof_n(trn_teof_n), 
    .trn_tsrc_rdy_n(trn_tsrc_rdy_n), 
    .trn_tsrc_dsc_n(trn_tsrc_dsc_n), 
    .trn_tdst_rdy_n(trn_tdst_rdy_n), 
    .trn_tdst_dsc_n(trn_tdst_dsc_n), 
    .trn_tbuf_av(trn_tbuf_av), 
    .req_compl_i(req_compl_i), 
    .compl_done_o(compl_done_o), 
    .req_tc_i(req_tc_i), 
    .req_td_i(req_td_i), 
    .req_ep_i(req_ep_i), 
    .req_attr_i(req_attr_i), 
    .req_len_i(req_len_i), 
    .req_rid_i(req_rid_i), 
    .req_tag_i(req_tag_i), 
    .req_be_i(req_be_i), 
    .req_addr_i(req_addr_i), 
    .rd_addr_o(rd_addr_o), 
    .rd_be_o(rd_be_o), 
    .rd_data_i(rd_data_i), 
    .init_rst_i(init_rst_i), 
    .mwr_start_i(mwr_start_i), 
    .mwr_int_dis_i(mwr_int_dis_i), 
    .mwr_len_i(mwr_len_i), 
    .mwr_lbe_i(mwr_lbe_i), 
    .mwr_fbe_i(mwr_fbe_i), 
    .mwr_addr_i(mwr_addr_i), 
    .mwr_count_i(mwr_count_i), 
    .mwr_done_o(mwr_done_o), 
    .mwr_tlp_tc_i(mwr_tlp_tc_i), 
    .mwr_64b_en_i(mwr_64b_en_i), 
    .mwr_phant_func_dis1_i(mwr_phant_func_dis1_i), 
    .mwr_up_addr_i(mwr_up_addr_i), 
    .mwr_relaxed_order_i(mwr_relaxed_order_i), 
    .mwr_nosnoop_i(mwr_nosnoop_i), 
    .cfg_msi_enable_i(cfg_msi_enable_i), 
    .cfg_interrupt_n_o(cfg_interrupt_n_o), 
    .cfg_interrupt_assert_n_o(cfg_interrupt_assert_n_o), 
    .cfg_interrupt_rdy_n_i(cfg_interrupt_rdy_n_i), 
    .cfg_interrupt_legacyclr(cfg_interrupt_legacyclr), 
    .completer_id_i(completer_id_i), 
    .cfg_ext_tag_en_i(cfg_ext_tag_en_i), 
    .cfg_bus_mstr_enable_i(cfg_bus_mstr_enable_i), 
    .cfg_phant_func_en_i(cfg_phant_func_en_i), 
    .cfg_phant_func_supported_i(cfg_phant_func_supported_i), 
    .xy_buf_addr_o(xy_buf_addr_o), 
    .xy_buf_dat_i(xy_buf_dat_i), 
    .wdma_irq_i(wdma_irq_i)
);

reg [63:0]      dina;
reg [7:0]       addra;
reg             wea;


wire [63:0]     doutb;
initial begin
    fofb_node_buffer = '1;
end

reg [7:0] xy_buf_addr_prev;

always @(posedge clk)
    xy_buf_addr_prev <=  xy_buf_addr_o[7:0];


assign xy_buf_dat_i = fofb_node_buffer[xy_buf_addr_prev] ? doutb : 64'h0;

fofb_cc_sdpbram
    # (
        .AW             (8                  ),
        .DW             (64                 )
    )

    xy (
        .addra          ( addra             ),
        .addrb          ( xy_buf_addr_o[7:0]),
        .clka           ( clk               ),
        .clkb           ( clk               ),
        .dina           ( dina              ),
        .doutb          ( doutb             ),
        .wea            ( wea               )
    );

initial begin
    wea = 0;
    addra = 0;
    dina = 0;
    repeat(100) @(posedge clk);
    for (i=0; i< 256; i=i+1) begin
        addra = i;
        dina = {32'(i), 32'(i)};
        if (i==1 || i==2 || i==3)
            wea = 1;
        else
            wea = 0;
        @(posedge clk);
    end
    wea = 0;
end

initial begin
    // Initialize Inputs
    req_compl_i = 0;
    req_tc_i = 0;
    req_td_i = 0;
    req_ep_i = 0;
    req_attr_i = 0;
    req_len_i = 0;
    req_rid_i = 0;
    req_tag_i = 0;
    req_be_i = 0;
    req_addr_i = 0;
    rd_data_i = 0;
    init_rst_i = 0;
    mwr_int_dis_i = 0;
    mwr_len_i = 32;
    mwr_count_i = 16;
    mwr_tag_i = 0;
    mwr_lbe_i = 0;
    mwr_fbe_i = 0;
    mwr_addr_i = 0;
    mwr_tlp_tc_i = 0;
    mwr_64b_en_i = 0;
    mwr_phant_func_dis1_i = 0;
    mwr_up_addr_i = 8'hFF;
    mwr_relaxed_order_i = 0;
    mwr_nosnoop_i = 0;
    mwr_wrr_cnt_i = 8;
    cfg_msi_enable_i = 0;
    cfg_interrupt_rdy_n_i = 0;
    cfg_interrupt_legacyclr = 0;
    completer_id_i = 0;
    cfg_ext_tag_en_i = 0;
    cfg_bus_mstr_enable_i = 1;
    cfg_phant_func_en_i = 0;
    cfg_phant_func_supported_i = 0;
    wdma_irq_i = 0;

    // Wait 100 ns for global reset to finish
    #100;
    // Add stimulus here
end

initial begin
    timeframe_end_i = 0;
    repeat(996) @(posedge clk);
    timeframe_end_i = 1;
    repeat(2000) @(posedge clk);
    timeframe_end_i = 0;
end

initial begin
    mwr_start_i = 0;
    repeat(1000) @(posedge clk);
    mwr_start_i = 1;
    repeat(5000) @(posedge clk);
    mwr_start_i = 0;
end

initial begin
    /* Test stimuli from PCI-E interface */
    trn_tdst_rdy_n = 0;
    trn_tdst_dsc_n = 1;
    trn_tbuf_av = 0;
    @(negedge trn_tsof_n);
    repeat(1) @(posedge clk);
    trn_tdst_rdy_n = 1;
    repeat(2) @(posedge clk);
    trn_tdst_rdy_n = 0;
end


endmodule

