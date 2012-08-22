`timescale 1ns / 1ns

module bmd_64_rwdma_fsm_tb;

// Inputs
reg clk;
reg rst_n;
reg init_rst_i;
reg wdma_done_i;
reg [31:0] next_wdma_addr_i;
reg [7:0] next_wdma_up_addr_i;
reg next_wdma_valid_i;
reg wdma_start_i;
reg wdma_stop_i;
reg [15:0] wdma_frame_len_i;
reg timeframe_end_rise_i;

// Outputs
wire wdma_rst_o;
wire wdma_start_o;
wire [39:0] wdma_addr_o;
wire wdma_irq_o;
wire wdma_running_o;
wire [15:0] wdma_irq_time_o;
wire [7:0] wdma_miss_cnt_o;
wire [15:0] wdma_buf_ptr_o;
wire [3:0] wdma_status_o;
wire cc_timeout_o;

integer i;

// Instantiate the Unit Under Test (UUT)
BMD_64_RWDMA_FSM uut (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .init_rst_i         ( init_rst_i            ),
    .wdma_rst_o         ( wdma_rst_o            ),

    .mwr_len_i          ( 10'd32                ),
    .mwr_count_i        ( 16'd16                ),

    .wdma_start_o       ( wdma_start_o          ),
    .wdma_addr_o        ( wdma_addr_o           ),
    .wdma_done_i        ( wdma_done_i           ),
    .wdma_irq_o         ( wdma_irq_o            ),

    .next_wdma_addr_i   ( next_wdma_addr_i      ),
    .next_wdma_up_addr_i( next_wdma_up_addr_i   ),
    .next_wdma_valid_i  ( next_wdma_valid_i     ),
    .wdma_start_i       ( wdma_start_i          ),
    .wdma_stop_i        ( wdma_stop_i           ),
    .wdma_running_o     ( wdma_running_o        ),
    .wdma_frame_len_i   ( wdma_frame_len_i      ),

    .timeframe_end_rise_i    ( timeframe_end_rise_i       ),
    .wdma_buf_ptr_o     ( wdma_buf_ptr_o        ),
    .wdma_status_o      ( wdma_status_o         ),
    .cc_timeout_o       ( cc_timeout_o          )
);

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

initial begin
    timeframe_end_rise_i = 0;
    repeat(100) @(posedge clk);
    forever begin
        timeframe_end_rise_i = 0;
        @(posedge clk);
        timeframe_end_rise_i = 0;
        repeat(9999) @(posedge clk);
    end
end

initial begin
    next_wdma_addr_i = 0;
    next_wdma_up_addr_i = 0;
    next_wdma_valid_i = 0;
    wdma_start_i = 0;
    repeat(125) @(posedge clk);
    // 1. Set initial dma address
    TSK_SET_ADDR;
    repeat(100) @(posedge clk);
    // 2. Start dma
    TSK_START;

    for (i=0; i< 0; i=i+1) begin
        TSK_SET_ADDR;
        repeat(20000) @(posedge clk);
    end
    repeat(50000) @(posedge clk);
    $finish;
end


/* Initialize Inputs */
initial begin
    init_rst_i = 0;
    wdma_done_i = 0;
    wdma_stop_i = 0;
    wdma_frame_len_i = 2;
end

initial begin
    wdma_done_i = 0;
    forever begin
        @(posedge wdma_start_o);
        repeat(1000) @(posedge clk);
        wdma_done_i = 1;
        @(posedge wdma_rst_o);
        wdma_done_i = 0;
    end
end

task TSK_SET_ADDR;
    begin
        next_wdma_addr_i = 32'h80000000;
        next_wdma_up_addr_i = 8'h0;
        next_wdma_valid_i = 1;
        @(posedge clk);
        next_wdma_valid_i = 0;
    end
endtask

task TSK_START;
    begin
        wdma_start_i = 1;
        @(posedge clk);
        wdma_start_i = 0;
    end
endtask

endmodule

