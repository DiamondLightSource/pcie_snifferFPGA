/*
 * Filename: BMD_64_RX_ENGINE.v
 *
 * Description: 64 bit Local-Link Receive Unit.
 */

`timescale 1ns/1ns

`define BMD_64_RX_RST            8'b00000001
`define BMD_64_RX_MEM_RD32_QW1   8'b00000010
`define BMD_64_RX_MEM_RD32_WT    8'b00000100
`define BMD_64_RX_MEM_WR32_QW1   8'b00001000
`define BMD_64_RX_MEM_WR32_WT    8'b00010000
`define BMD_64_RX_CPL_QW1        8'b00100000
`define BMD_64_RX_CPLD_QW1       8'b01000000
`define BMD_64_RX_CPLD_QWN       8'b10000000

`define BMD_MEM_RD32_FMT_TYPE    7'b00_00000
`define BMD_MEM_WR32_FMT_TYPE    7'b10_00000
`define BMD_CPL_FMT_TYPE         7'b00_01010
`define BMD_CPLD_FMT_TYPE        7'b10_01010

module BMD_RX_ENGINE (
    clk,
    rst_n,

    /*
     * Initiator reset
     */
    init_rst_i,

    /*
     * Receive local link interface from PCIe core
     */
    trn_rd,
    trn_rsof_n,
    trn_reof_n,
    trn_rsrc_rdy_n,
    trn_rdst_rdy_n,

    /*
     * Memory Read data handshake with Completion 
     * transmit unit. Transmit unit reponds to 
     * req_compl assertion and responds with compl_done
     * assertion when a Completion w/ data is transmitted. 
     */
    req_compl_o,
    compl_done_i,
    addr_o,                    // Memory Read Address
    req_tc_o,                  // Memory Read TC
    req_td_o,                  // Memory Read TD
    req_ep_o,                  // Memory Read EP
    req_attr_o,                // Memory Read Attribute
    req_len_o,                 // Memory Read Length (1DW)
    req_rid_o,                 // Memory Read Requestor ID
    req_tag_o,                 // Memory Read Tag
    req_be_o,                  // Memory Read Byte Enables

    /* 
     * Memory interface used to save 1 DW data received 
     * on Memory Write 32 TLP. Data extracted from
     * inbound TLP is presented to the Endpoint memory
     * unit. Endpoint memory unit reacts to wr_en_o
     * assertion and asserts wr_busy_i when it is 
     * processing written information.
     */
    wr_be_o,                   // Memory Write Byte Enable
    wr_data_o,                 // Memory Write Data
    wr_en_o,                   // Memory Write Enable
    wr_busy_i                  // Memory Write Busy
);

input              clk;
input              rst_n;

input              init_rst_i;

input [63:0]       trn_rd;
input              trn_rsof_n;
input              trn_reof_n;
input              trn_rsrc_rdy_n;
output             trn_rdst_rdy_n;

output             req_compl_o;
input              compl_done_i;

output [10:0]      addr_o;

output [2:0]       req_tc_o;
output             req_td_o;
output             req_ep_o;
output [1:0]       req_attr_o;
output [9:0]       req_len_o;
output [15:0]      req_rid_o;
output [7:0]       req_tag_o;
output [7:0]       req_be_o;

output [7:0]       wr_be_o;
output [31:0]      wr_data_o;
output             wr_en_o;
input              wr_busy_i;

/* Local Registers */

reg [7:0]          bmd_64_rx_state;

reg                trn_rdst_rdy_n;

reg                req_compl_o;

reg [2:0]          req_tc_o;
reg                req_td_o;
reg                req_ep_o;
reg [1:0]          req_attr_o;
reg [9:0]          req_len_o;
reg [15:0]         req_rid_o;
reg [7:0]          req_tag_o;
reg [7:0]          req_be_o;

reg [10:0]         addr_o;
reg [7:0]          wr_be_o;
reg [31:0]         wr_data_o;
reg                wr_en_o;


always @ ( posedge clk ) begin
    if (!rst_n ) begin
        bmd_64_rx_state   <= `BMD_64_RX_RST;

        trn_rdst_rdy_n <= 1'b0;

        req_compl_o    <= 1'b0;

        req_tc_o       <= 2'b0;
        req_td_o       <= 1'b0;
        req_ep_o       <= 1'b0;
        req_attr_o     <= 2'b0;
        req_len_o      <= 10'b0;
        req_rid_o      <= 16'b0;
        req_tag_o      <= 8'b0;
        req_be_o       <= 8'b0;
        addr_o         <= 31'b0;

        wr_be_o        <= 8'b0;
        wr_data_o      <= 31'b0;
        wr_en_o        <= 1'b0;
    end
    else begin

        wr_en_o        <= 1'b0;
        req_compl_o    <= 1'b0;
        trn_rdst_rdy_n <= 1'b0;

        if (init_rst_i) begin
            bmd_64_rx_state  <= `BMD_64_RX_RST;
        end

        case (bmd_64_rx_state)
            `BMD_64_RX_RST : begin
                if ((!trn_rsof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    case (trn_rd[62:56])
                        `BMD_MEM_RD32_FMT_TYPE : begin

                            if (trn_rd[41:32] == 10'b1) begin
                                req_tc_o     <= trn_rd[54:52];
                                req_td_o     <= trn_rd[47];
                                req_ep_o     <= trn_rd[46]; 
                                req_attr_o   <= trn_rd[45:44];
                                req_len_o    <= trn_rd[41:32];
                                req_rid_o    <= trn_rd[31:16];
                                req_tag_o    <= trn_rd[15:08];
                                req_be_o     <= trn_rd[07:00];
                                bmd_64_rx_state <= `BMD_64_RX_MEM_RD32_QW1;
                            end 
                            else
                            bmd_64_rx_state <= `BMD_64_RX_RST;
                        end

                        `BMD_MEM_WR32_FMT_TYPE : begin
                            if (trn_rd[41:32] == 10'b1) begin
                                wr_be_o      <= trn_rd[07:00];
                                bmd_64_rx_state <= `BMD_64_RX_MEM_WR32_QW1;
                            end
                            else
                                bmd_64_rx_state <= `BMD_64_RX_RST;
                        end

                        `BMD_CPL_FMT_TYPE : begin
                            if (trn_rd[15:12] != 3'b000) begin
                                bmd_64_rx_state   <= `BMD_64_RX_CPL_QW1;
                            end
                            else
                                bmd_64_rx_state   <= `BMD_64_RX_RST;
                        end

                        `BMD_CPLD_FMT_TYPE : begin
                            bmd_64_rx_state  <= `BMD_64_RX_CPLD_QW1;
                        end

                        default : begin
                            bmd_64_rx_state   <= `BMD_64_RX_RST;
                        end
                    endcase
                end 
                else
                    bmd_64_rx_state   <= `BMD_64_RX_RST;
            end

            `BMD_64_RX_MEM_RD32_QW1 : begin
                if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    addr_o            <= trn_rd[63:34];
                    req_compl_o       <= 1'b1;
                    trn_rdst_rdy_n    <= 1'b1;
                    bmd_64_rx_state   <= `BMD_64_RX_MEM_RD32_WT;
                end 
                else
                    bmd_64_rx_state   <= `BMD_64_RX_MEM_RD32_QW1;
                end

            `BMD_64_RX_MEM_RD32_WT: begin
                trn_rdst_rdy_n <= 1'b1;
                if (compl_done_i)
                    bmd_64_rx_state   <= `BMD_64_RX_RST;
                else begin
                    req_compl_o       <= 1'b1;
                    trn_rdst_rdy_n    <= 1'b1;
                    bmd_64_rx_state   <= `BMD_64_RX_MEM_RD32_WT;
                end
            end

            `BMD_64_RX_MEM_WR32_QW1 : begin
                if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    addr_o           <= trn_rd[44:34];
                    wr_data_o        <= trn_rd[31:00];
                    wr_en_o          <= 1'b1;
                    trn_rdst_rdy_n   <= 1'b1;
                    bmd_64_rx_state  <= `BMD_64_RX_MEM_WR32_WT;
                end else
                    bmd_64_rx_state  <= `BMD_64_RX_MEM_WR32_QW1;
            end

            `BMD_64_RX_MEM_WR32_WT: begin
                trn_rdst_rdy_n <= 1'b1;
                if (!wr_busy_i)
                    bmd_64_rx_state  <= `BMD_64_RX_RST;
                else
                    bmd_64_rx_state  <= `BMD_64_RX_MEM_WR32_WT;
            end

            `BMD_64_RX_CPL_QW1 : begin
                if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    bmd_64_rx_state  <= `BMD_64_RX_RST;
                end else
                    bmd_64_rx_state  <= `BMD_64_RX_CPL_QW1;
            end

            `BMD_64_RX_CPLD_QW1 : begin
                if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    bmd_64_rx_state  <= `BMD_64_RX_RST;
                end 
                else if ((!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    bmd_64_rx_state  <= `BMD_64_RX_CPLD_QWN;
                end
                else
                    bmd_64_rx_state   <= `BMD_64_RX_CPLD_QW1;
            end

            `BMD_64_RX_CPLD_QWN : begin
                if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    bmd_64_rx_state  <= `BMD_64_RX_RST;
                end 
                else if ((!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n)) begin
                    bmd_64_rx_state  <= `BMD_64_RX_CPLD_QWN;
                end
                else
                    bmd_64_rx_state   <= `BMD_64_RX_CPLD_QWN;
            end
        endcase
    end
end

endmodule // BMD_64_RX_ENGINE
