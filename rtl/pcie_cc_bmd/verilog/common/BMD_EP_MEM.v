/*
 * Filename: BMD_EP_MEM.v
 * Description: Endpoint control and status registers
 */

`timescale 1ns/1ns

module BMD_EP_MEM# (
    parameter INTERFACE_TYPE = 4'b0010,
    parameter FPGA_FAMILY = 8'h14
)
(
    clk,                   // I
    rst_n,                 // I

    cfg_cap_max_lnk_width, // I [5:0]
    cfg_neg_max_lnk_width, // I [5:0]

    cfg_cap_max_payload_size,  // I [2:0]
    cfg_prg_max_payload_size,  // I [2:0]
    cfg_max_rd_req_size,   // I [2:0]

    a_i,                   // I [8:0]
    wr_en_i,               // I 
    rd_d_o,                // O [31:0]
    wr_d_i,                // I [31:0]

    init_rst_o,            // O

    mwr_start_o,           // O
    mwr_int_dis_o,         // O 
    mwr_addr_o,            // O [31:0]
    mwr_len_o,             // O [31:0]
    mwr_tlp_tc_o,          // O [2:0]
    mwr_64b_en_o,          // O
    mwr_phant_func_dis1_o,  // O
    mwr_up_addr_o,         // O [7:0]
    mwr_count_o,           // O [31:0]
    mwr_data_o,            // O [31:0]
    mwr_relaxed_order_o,   // O
    mwr_nosnoop_o,         // O

    cpl_streaming_o,       // O
    cfg_interrupt_di,      // O
    cfg_interrupt_do,      // I
    cfg_interrupt_mmenable,   // I
    cfg_interrupt_msienable,  // I
    cfg_interrupt_legacyclr,  // O
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
    pl_width_change_err_i,
    pl_speed_change_err_i,
    clr_pl_width_change_err,
    clr_pl_speed_change_err,
    clear_directed_speed_change_i,
`endif
    trn_rnp_ok_n_o,
    trn_tstr_n_o,

    fai_cfg_val_o,
    mwr_stop_o,
    wdma_buf_ptr_i,
    wdma_status_i,
    next_wdma_valid_o,
    fofb_rxlink_up_i,
    fofb_rxlink_partner_i,
    fofb_cc_timeout_i,
    harderror_cnt_i,
    softerror_cnt_i,
    frameerror_cnt_i
);

input             clk;
input             rst_n;

input [5:0]       cfg_cap_max_lnk_width;
input [5:0]       cfg_neg_max_lnk_width;

input [2:0]       cfg_cap_max_payload_size;
input [2:0]       cfg_prg_max_payload_size;
input [2:0]       cfg_max_rd_req_size;

input [6:0]       a_i;
input             wr_en_i;
output [31:0]     rd_d_o;
input  [31:0]     wr_d_i;

// CSR bits

output            init_rst_o;

output            mwr_start_o;
output            mwr_int_dis_o;
output [31:0]     mwr_addr_o;
output [9:0]     mwr_len_o;
output [2:0]      mwr_tlp_tc_o;
output            mwr_64b_en_o;
output            mwr_phant_func_dis1_o;
output [7:0]      mwr_up_addr_o;
output [15:0]     mwr_count_o;
output [15:0]     mwr_data_o;
output            mwr_relaxed_order_o;
output            mwr_nosnoop_o;

output            cpl_streaming_o;

output            trn_rnp_ok_n_o;
output            trn_tstr_n_o;
output [7:0]      cfg_interrupt_di;
input  [7:0]      cfg_interrupt_do;
input  [2:0]      cfg_interrupt_mmenable;
input             cfg_interrupt_msienable;
output            cfg_interrupt_legacyclr;

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

input             pl_width_change_err_i;
input             pl_speed_change_err_i;
output            clr_pl_width_change_err;
output            clr_pl_speed_change_err;
input             clear_directed_speed_change_i;
`endif

output [31:0]       fai_cfg_val_o;
output              mwr_stop_o;
input  [15:0]       wdma_buf_ptr_i;
input  [3:0]        wdma_status_i;
output              next_wdma_valid_o;
input               fofb_rxlink_up_i;
input  [9:0]        fofb_rxlink_partner_i;
input               fofb_cc_timeout_i;
input  [15: 0]      harderror_cnt_i;
input  [15: 0]      softerror_cnt_i;
input  [15: 0]      frameerror_cnt_i;

reg [31:0]          fai_cfg_val_o;
reg                 mwr_stop_o;

// Local Regs

reg [31:0]        rd_d_o /* synthesis syn_direct_enable = 0 */; 
reg               init_rst_o;

reg               mwr_start_o;
reg               mwr_int_dis_o;
reg [31:0]        mwr_addr_o;
reg [9:0]         mwr_len_o;
reg [15:0]        mwr_count_o;
reg [15:0]        mwr_data_o;
reg [2:0]         mwr_tlp_tc_o;
reg               mwr_64b_en_o;
reg               mwr_phant_func_dis1_o;
reg [7:0]         mwr_up_addr_o;
reg               mwr_relaxed_order_o;
reg               mwr_nosnoop_o;

reg               cpl_streaming_o;
reg               trn_rnp_ok_n_o;
reg               trn_tstr_n_o;

reg [7:0]         INTDI;
reg               LEGACYCLR;

`ifdef PCIE2_0
reg [1:0]         pl_directed_link_change;
reg [1:0]         pl_directed_link_width;
wire              pl_directed_link_speed;
reg [1:0]         pl_directed_link_speed_binary;
reg               pl_directed_link_auton;
reg               pl_upstream_preemph_src;
reg               pl_width_change_err;
reg               pl_speed_change_err;
reg               clr_pl_width_change_err;
reg               clr_pl_speed_change_err;
wire [1:0]        pl_sel_link_rate_binary;
`endif

wire [7:0]        fpga_family;
wire [3:0]        interface_type;
wire [15:0]       version_number;

//assign version_number
`include "pcie_cc_version.v"

assign interface_type = INTERFACE_TYPE;
assign fpga_family = FPGA_FAMILY;

assign cfg_interrupt_di[7:0] = INTDI[7:0];
assign cfg_interrupt_legacyclr = LEGACYCLR;
//assign cfg_interrupt_di = 8'haa;

`ifdef PCIE2_0
   assign pl_sel_link_rate_binary = (pl_sel_link_rate == 0) ? 2'b01 : 2'b10;
   assign pl_directed_link_speed = (pl_directed_link_speed_binary == 2'b01) ?
`endif

reg addr_val_lower;
reg addr_val_upper;
assign next_wdma_valid_o = addr_val_lower && addr_val_upper;

always @(posedge clk ) begin
    if ( !rst_n ) begin
        init_rst_o  <= 1'b0;
        mwr_phant_func_dis1_o <= 1'b0;
        mwr_start_o <= 1'b0;
        mwr_stop_o <= 1'b0;
        mwr_int_dis_o <= 1'b0;
        mwr_addr_o  <= 32'b0;
        mwr_len_o   <= 10'b0;
        mwr_count_o <= 16'b0;
        mwr_data_o  <= 16'b0;
        mwr_tlp_tc_o <= 3'b0;
        mwr_64b_en_o <= 1'b0;
        mwr_up_addr_o <= 8'b0;
        mwr_relaxed_order_o <= 1'b0;
        mwr_nosnoop_o <= 1'b0;

        cpl_streaming_o <= 1'b1;
        trn_rnp_ok_n_o <= 1'b0;
        trn_tstr_n_o <= 1'b0;

        fai_cfg_val_o <= 32'h0;
        addr_val_lower <= 1'b0;
        addr_val_upper <= 1'b0;
`ifdef PCIE2_0
        clr_pl_width_change_err <= 1'b0;
        clr_pl_speed_change_err <= 1'b0;
        pl_directed_link_change <= 2'h0;
        pl_directed_link_width  <= 2'h0;
        pl_directed_link_speed_binary  <= 2'b0; 
        pl_directed_link_auton  <= 1'b0;
        pl_upstream_preemph_src <= 1'b0;
        pl_width_change_err     <= 0;
        pl_speed_change_err     <= 0;
`endif
        INTDI   <= 8'h00;
        LEGACYCLR  <=  1'b0;
    end
    else begin

`ifdef PCIE2_0
        if (a_i[6:0] != 7'b010011) begin  // Reg#19
            pl_width_change_err <= pl_width_change_err_i;
            pl_speed_change_err <= pl_speed_change_err_i;
            pl_directed_link_change <= clear_directed_speed_change_i ? 0 :    // 1
                                       pl_directed_link_change;               // 0
        end
`endif

        /* Generate data valid pulse when both upper and lower addr are written*/
        if (addr_val_lower && addr_val_upper)
            addr_val_lower <= 1'b0;
        else if (a_i[6:0] == 7'b0000010 && wr_en_i)
            addr_val_lower <= 1'b1;

        if (addr_val_lower && addr_val_upper)
            addr_val_upper <= 1'b0;
        else if (a_i[6:0] == 7'b0000011 && wr_en_i)
            addr_val_upper <= 1'b1;

        mwr_start_o <= 1'b0;
        mwr_stop_o <= 1'b0;

        case (a_i[6:0])

            // 00-03H : Reg # 0 
            // Byte0[0]: Initiator Reset (RW) 0= no reset 1=reset.
            // Byte2[19:16]: Data Path Width
            // Byte3[31:24]: FPGA Family
            7'b0000000: begin
                if (wr_en_i)
                    init_rst_o  <= wr_d_i[0];

                    rd_d_o <= {fpga_family, {4'b0}, interface_type, version_number};

                    if (init_rst_o) begin
                        mwr_start_o <= 1'b0;
                        mwr_stop_o <= 1'b0;
                    end

            end

            // 04-07H :  Reg # 1
            // Byte0[0]: Memory Write Start (RW) 0=no start, 1=start
            // Byte0[7]: Memory Write Inter Disable (RW) 1=disable
            // Byte1[0]: Memory Write Done  (RO) 0=not done, 1=done
            // Byte2[0]: Memory Read Start (RW) 0=no start, 1=start
            // Byte2[7]: Memory Read Inter Disable (RW) 1=disable
            // Byte3[0]: Memory Read Done  (RO) 0=not done, 1=done
            7'b0000001: begin
                if (wr_en_i) begin
                    mwr_start_o  <= wr_d_i[0];
                    mwr_stop_o <= wr_d_i[1];
                    mwr_relaxed_order_o <=  wr_d_i[5];
                    mwr_nosnoop_o <= wr_d_i[6];
                    mwr_int_dis_o <= wr_d_i[7];
                end 
            end

            // 08-0BH : Reg # 2
            // Memory Write DMA Address (RW)
            7'b0000010: begin
                if (wr_en_i)
                    mwr_addr_o  <= wr_d_i;
                rd_d_o <= mwr_addr_o;
            end

            // 0C-0FH : Reg # 3
            // Memory Write length in DWORDs (RW)
            7'b0000011: begin
                if (wr_en_i) begin
                    mwr_len_o  <= wr_d_i[9:0];
                    mwr_tlp_tc_o  <= wr_d_i[18:16];
                    mwr_64b_en_o <= wr_d_i[19];
                    mwr_phant_func_dis1_o <= wr_d_i[20];
                    mwr_up_addr_o <= wr_d_i[31:24];
                end
                rd_d_o <= {mwr_up_addr_o, 3'b0, mwr_phant_func_dis1_o, mwr_64b_en_o, mwr_tlp_tc_o, 6'h0, mwr_len_o[9:0]};
            end

            // 10-13H : Reg # 4
            // Memory Write Packet Count (RW)
            7'b0000100: begin
                if (wr_en_i)
                    mwr_count_o  <= wr_d_i[15:0];
            end

            // 14-17H : Reg # 5
            // Memory Write Packet DWORD Data (RW)
            7'b000101: begin
                if (wr_en_i)
                    mwr_data_o  <= wr_d_i[15:0];
            end

            // 3C-3FH : Reg # 15
            // Link Width (RO)
            7'b001111: begin
                rd_d_o <= { 16'b0,
                            2'b0, cfg_neg_max_lnk_width, 
                            2'b0, cfg_cap_max_lnk_width};
            end

            // 40-43H : Reg # 16
            // Link Payload (RO)
            7'b010000: begin
                rd_d_o <= { 8'b0,
                            5'b0, cfg_max_rd_req_size, 
                            5'b0, cfg_prg_max_payload_size, 
                            5'b0, cfg_cap_max_payload_size};
            end

            // 44-47H : Reg # 17
            // WRR MWr
            // WRR MRd
            // Rx NP TLP Control
            // Completion Streaming Control (RW)
            // Read Metering Control (RW)
            7'b010001: begin
                if (wr_en_i) begin
                    cpl_streaming_o <= wr_d_i[0];
                    trn_rnp_ok_n_o <= wr_d_i[8];
                    trn_tstr_n_o <= wr_d_i[9];
                end
            end

            // 48-4BH : Reg # 18
            // INTDI (RW)
            // INTDO
            // MMEN
            // MSIEN
            7'b010010: begin
                if (wr_en_i) begin
                    INTDI[7:0] <= wr_d_i[7:0];
                    LEGACYCLR <= wr_d_i[8];
                end
                rd_d_o <= { 4'h0, 
                            cfg_interrupt_msienable,
                            cfg_interrupt_mmenable[2:0],
                            cfg_interrupt_do[7:0],
                            7'h0, LEGACYCLR,
                            INTDI[7:0]};
            end

`ifdef PCIE2_0
            // 4C-4FH : Reg # 19
            // CHG(RW), LTS, TW(RW), TS(RW), A(RW), P(RW), CW, CS, G2S, PG2S, 
            // LILW, LUC, SCE, WCE, LR

            7'b010011: begin
               if (wr_en_i) begin
                   clr_pl_width_change_err       <= wr_d_i[29];
                   clr_pl_speed_change_err       <= wr_d_i[28];
                   pl_upstream_preemph_src       <= wr_d_i[15];    // P
                   pl_directed_link_auton        <= wr_d_i[14];    // A
                   pl_directed_link_speed_binary <= wr_d_i[13:12]; // TS
                   pl_directed_link_width        <= wr_d_i[9:8];   // TW
                   pl_directed_link_change       <= wr_d_i[1:0];   // CHG
               end else
               begin
                   clr_pl_width_change_err          <= 1'b0;
                   clr_pl_speed_change_err          <= 1'b0;

                   pl_directed_link_change <= clear_directed_speed_change_i ?
                                      0 : pl_directed_link_change;  
               end

               rd_d_o <= {  pl_lane_reversal_mode[1:0],        //LR   31:30
                            pl_width_change_err,               //WCE     29
                            pl_speed_change_err,               //SCE     28
                            pl_link_upcfg_capable,             //LUC     27
                            pl_initial_link_width[2:0],        //LILW 26:24
                            pl_link_partner_gen2_supported,    //PG2S    23
                            pl_link_gen2_capable,              //G2S     22
                            pl_sel_link_rate_binary[1:0],      //CS   21:20
                            2'b0,                              //R1   19:18
                            pl_sel_link_width[1:0],            // CW  17:16
                            pl_upstream_preemph_src,           //P       15
                            pl_directed_link_auton,            //A       14
                            pl_directed_link_speed_binary[1:0],//TS   13:12
                            2'b0,                              //R0   11:10 
                            pl_directed_link_width[1:0],       //TW    9: 8
                            pl_ltssm_state[5:0],               //LTS   7: 2
                            pl_directed_link_change[1:0]       //CHG   1: 0
                          };
            end
`endif
            // 80-83H : Reg # 32
            // CC Control Register
            7'b100000: begin
                 if (wr_en_i)
                     fai_cfg_val_o <= wr_d_i;
                 rd_d_o <= fai_cfg_val_o;
            end

            // 84-87H : Reg # 33
            // IRQ Response Interval Counter
            7'b100001: begin 
                 rd_d_o <= { 16'h0,
                             wdma_buf_ptr_i,        // [23:8]
                             4'b0, wdma_status_i};  // [7:0]
            end

            // 88-8BH : Reg # 34
            // IRQ Response Interval Counter
            7'b100010: begin
                 rd_d_o <= { 8'h0,
                             5'h0,fofb_rxlink_partner_i,
                             6'h0, fofb_cc_timeout_i, fofb_rxlink_up_i };
            end

            // 8C-8F : Reg # 35
            // Frame error cnt
            7'b100011: begin
                rd_d_o <= {16'h0, frameerror_cnt_i};
            end

            // 90-93 : Reg # 36
            // Soft error cnt
            7'b100100: begin
                rd_d_o <= {16'h0, softerror_cnt_i};
            end

            // 94-97 : Reg # 37
            // Hard error cnt
            7'b100101: begin
                rd_d_o <= {16'h0, harderror_cnt_i};
            end

            default: begin
                rd_d_o <= 32'b0;
            end
        endcase
    end
end

endmodule

