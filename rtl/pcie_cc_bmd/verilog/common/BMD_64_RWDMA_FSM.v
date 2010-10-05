`timescale 1ns/1ns

`define WDMA_IDLE               6'h01
`define WDMA_LOAD               6'h02
`define WDMA_WAIT_CC            6'h04
`define WDMA_DOING_DMA          6'h08
`define WDMA_CHECK              6'h10
`define WDMA_STOPPED            6'h20

module BMD_64_RWDMA_FSM (
    // Clocks and resets
    clk,
    rst_n,
    init_rst_i,
    wdma_rst_o,

    // DMA Engine interface
    wdma_start_o,
    wdma_addr_o,
    wdma_done_i,
    wdma_irq_o,

    // FSM control interface
    next_wdma_addr_i,
    next_wdma_up_addr_i,
    next_wdma_valid_i,
    wdma_start_i,
    wdma_stop_i,
    wdma_running_o,
    wdma_frame_len_i,

    // CC interface
    timeframe_end_rise_i,

    // WDMA status
    wdma_buf_ptr_o,
    wdma_status_o,
    cc_timeout_o
);

input           clk;
input           rst_n;
input           init_rst_i;
output          wdma_rst_o;

output          wdma_start_o;
output [39:0]   wdma_addr_o;
input           wdma_done_i;
output          wdma_irq_o;

input  [31:0]   next_wdma_addr_i;
input  [7:0]    next_wdma_up_addr_i;
input           next_wdma_valid_i;
input           wdma_start_i;
input           wdma_stop_i;
output          wdma_running_o;
input  [15:0]   wdma_frame_len_i;

input           timeframe_end_rise_i;

output [15:0]   wdma_buf_ptr_o;
output [3:0]    wdma_status_o;
output          cc_timeout_o;

reg    [39:0]   wdma_addr_o;
reg             wdma_irq_o;
reg             wdma_start_o;
reg             wdma_running_o;
reg    [3:0]    wdma_status_o;

/*
 * Registers
 */
reg             timeframe_end_rise_prev;
reg [15:0]      wdma_buf_cnt;
reg [5:0]       wdma_state;
reg [5:0]       wdma_state_prev;

/*
 * Local wires
 */

/* Buffer length in number of frames, each frame is 2Kbytes */
wire [15:0]     wdma_buf_size = wdma_frame_len_i[15:0];

wire            wdma_rst_o = timeframe_end_rise_i && (wdma_state == `WDMA_WAIT_CC);
/* Write pointer value to user app */
wire [15:0]     wdma_buf_ptr_o = wdma_buf_cnt;

reg         next_wdma_valid;
reg         wdma_stop;
reg [15:0]  cnt_16bit;
wire        cc_timeout_o = cnt_16bit[15];

always @ (posedge clk)
begin
    if (!rst_n) begin
        cnt_16bit = 0;
    end
    else begin

        if (init_rst_i || wdma_start_i || timeframe_end_rise_i)
            cnt_16bit = 0;
        else if (!cnt_16bit[15])
            cnt_16bit = cnt_16bit + 1;
    end
end

always @ (posedge clk)
begin
    if (!rst_n) begin
        wdma_state <= `WDMA_IDLE;
        timeframe_end_rise_prev <= 1'b0;
        wdma_addr_o <= 40'h0;
        wdma_irq_o <= 1'b0;
        wdma_start_o <= 1'b0;
        wdma_buf_cnt <=  16'h0;
        next_wdma_valid <= 1'b0;
        wdma_running_o <= 1'b0;
        wdma_status_o <= 4'b0000;
        wdma_stop <= 1'b0;
    end
    else begin

        if (init_rst_i) begin
            wdma_state <= `WDMA_IDLE;
            wdma_state_prev <= `WDMA_IDLE;
            wdma_addr_o <= 40'h0;
            wdma_irq_o <= 1'b0;
            wdma_start_o <= 1'b0;
            wdma_buf_cnt <=  16'h0;
            wdma_running_o <= 1'b0;
            wdma_status_o <= 4'b0000;
            wdma_stop <= 1'b0;
        end

        wdma_state_prev <= wdma_state;

        /* Extra FF for clock domain crossing */
        timeframe_end_rise_prev <= timeframe_end_rise_i;

        if (next_wdma_valid_i)
            next_wdma_valid <= 1'b1;
        else if ((wdma_state == `WDMA_LOAD && next_wdma_valid && !wdma_stop)
                        || wdma_state == `WDMA_STOPPED)
            next_wdma_valid <= 1'b0;

        if (wdma_stop_i)
            wdma_stop <= 1'b1;
        else if (wdma_state == `WDMA_STOPPED)
            wdma_stop <= 1'b0;

        case (wdma_state)
            `WDMA_IDLE : begin
                if (wdma_start_i)
                    wdma_state <= `WDMA_LOAD;
            end

            `WDMA_LOAD : begin
                wdma_buf_cnt <= 16'h0;
                if (next_wdma_valid && !wdma_stop) begin
                    wdma_state <= `WDMA_WAIT_CC;
                    wdma_addr_o <= {next_wdma_up_addr_i, next_wdma_addr_i};
                    wdma_running_o <= 1'b1;
                end
                else begin
                    wdma_state <= `WDMA_STOPPED;
                end

                if ((!next_wdma_valid || wdma_stop) && wdma_state_prev != `WDMA_CHECK)
                    wdma_irq_o <= 1'b1;
                else
                    wdma_irq_o <= 1'b0;
            end

            `WDMA_WAIT_CC : begin
                if (cc_timeout_o) begin
                    wdma_state <= `WDMA_STOPPED;
                    wdma_irq_o <= 1'b1;
                end
                else if (timeframe_end_rise_prev) begin
                    wdma_start_o <= 1'b1;
                    wdma_state <= `WDMA_DOING_DMA;
                end
            end

            `WDMA_DOING_DMA : begin
                if (wdma_done_i) begin
                    wdma_start_o <= 1'b0;
                    wdma_addr_o <= wdma_addr_o + 2048;
                    wdma_buf_cnt <=  wdma_buf_cnt + 1;
                    wdma_state <= `WDMA_CHECK;
                end
            end

            `WDMA_CHECK : begin
                if (wdma_stop) begin
                    wdma_state <= `WDMA_STOPPED;
                    wdma_irq_o <= 1'b1;
                end
                else if (wdma_buf_cnt == wdma_buf_size) begin
                    wdma_irq_o <= 1'b1;
                    wdma_state <= `WDMA_LOAD;
                end
                else
                    wdma_state <= `WDMA_WAIT_CC;
            end

            `WDMA_STOPPED : begin
                wdma_irq_o <= 1'b0;
                wdma_running_o <= 1'b0;
            end

        endcase

        /* Status information on IRQ */
        /* Completed the dma, and next dma is in progress */
        if (wdma_state == `WDMA_LOAD && wdma_state_prev == `WDMA_CHECK && next_wdma_valid && !wdma_stop)
            wdma_status_o <= 4'b0001;
        /* Completed the dma, next dma is not valid */
        else if (wdma_state == `WDMA_LOAD && wdma_state_prev == `WDMA_CHECK && !next_wdma_valid && !wdma_stop)
            wdma_status_o <= 4'b0011;
        /* No dma taken place, next dma is not valid */
        else if (wdma_state == `WDMA_LOAD && wdma_state_prev != `WDMA_CHECK && !next_wdma_valid && !wdma_stop)
            wdma_status_o <= 4'b0010;
        /* User intervention for stop */
        else if ((wdma_state == `WDMA_CHECK || wdma_state == `WDMA_LOAD) && wdma_stop)
            wdma_status_o <= 4'b0100;
        /* Communication Controller timed out (no incoming data for 300us) */
        else if (wdma_state == `WDMA_WAIT_CC && cc_timeout_o)
            wdma_status_o <= 4'b1000;

    end
end

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
//    .clk                        ( clk                       ),
//    .data                       ( data                      ),
//    .trig0                      ( trig                      )
//);
//
//assign trig[0] = init_rst_i;
//assign trig[1] = wdma_start_o;
//assign trig[2] = timeframe_end_rise;
//
//assign data[0] = init_rst_i;
//assign data[1] = wdma_start_o;
//assign data[2] = timeframe_end_i;
//assign data[3] = timeframe_end_rise;
//assign data[4] = cc_timeout_o;
//assign data[10:5] = wdma_state;
//assign data[14:11] = wdma_status_o;

//assign data[31:0] = wdma_addr_o[31:0];
//assign data[63:32] = next_wdma_addr_i;
//assign data[79:64] = wdma_buf_size;
//assign data[95:80] = wdma_buf_cnt;
//assign data[101:96] = wdma_state;
//assign data[102] = wdma_start_o;
//assign data[103] = wdma_done_i;
//assign data[104] = wdma_irq_o;
//assign data[105] = init_rst_i;
//assign data[106] = cc_timeout_o;
//assign data[107] = wdma_stop;
//assign data[108] = wdma_start_i;
//assign data[109] = next_wdma_valid_i;
//assign data[110] = next_wdma_valid;
//assign data[114:111] = wdma_status_o;
//assign data[122:115] = next_wdma_up_addr_i;

endmodule
