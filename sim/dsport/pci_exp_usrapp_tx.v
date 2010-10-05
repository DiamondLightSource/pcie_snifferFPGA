
//-- Copyright(C) 2008 by Xilinx, Inc. All rights reserved.
//-- This text contains proprietary, confidential
//-- information of Xilinx, Inc., is distributed
//-- under license from Xilinx, Inc., and may be used,
//-- copied and/or disclosed only pursuant to the terms
//-- of a valid license agreement with Xilinx, Inc. This copyright
//-- notice must be retained as part of this text at all times.

`include "board_common.v"

module pci_exp_usrapp_tx                     (

                                               trn_td,
                                               trn_trem_n,
                                               trn_tsof_n,
                                               trn_teof_n,
                                               trn_terrfwd_n,
                                               trn_tsrc_rdy_n,
                                               trn_tsrc_dsc_n,

                                               trn_clk,
                                               trn_reset_n,
                                               trn_lnk_up_n,
                                               trn_tdst_rdy_n,
                                               trn_tdst_dsc_n,
                                               trn_tbuf_av

                                             );

output [(64 - 1):0]       trn_td;
output [(8 - 1):0]        trn_trem_n;
output                                         trn_tsof_n;
output                                         trn_teof_n;
output                                         trn_terrfwd_n;
output                                         trn_tsrc_rdy_n;
output                                         trn_tsrc_dsc_n;

input                                          trn_clk;
input                                          trn_reset_n;
input                                          trn_lnk_up_n;
input                                          trn_tdst_rdy_n;
input                                          trn_tdst_dsc_n;
input  [(5 - 1):0]     trn_tbuf_av;


/* Output Variables */

reg [(64 - 1):0]          trn_td;
reg [(8 - 1):0]           trn_trem_n;
reg                                            trn_tsof_n;
reg                                            trn_teof_n;
reg                                            trn_terrfwd_n;
reg                                            trn_tsrc_rdy_n;
reg                                            trn_tsrc_dsc_n;

/* Local Variables */

integer                                        i, j, k;
reg  [7:0]                                     DATA_STORE [4095:0];
reg  [31:0]                                    ADDRESS_32_L;
reg  [31:0]                                    ADDRESS_32_H;
reg  [63:0]                                    ADDRESS_64;
reg  [15:0]                                    COMPLETER_ID;
reg  [15:0]                                    COMPLETER_ID_CFG;
reg  [15:0]                                    REQUESTER_ID;
reg  [15:0]                                    DESTINATION_RID;
reg  [2:0]                                     DEFAULT_TC;
reg  [9:0]                                     DEFAULT_LENGTH;
reg  [3:0]                                     DEFAULT_BE_LAST_DW;
reg  [3:0]                                     DEFAULT_BE_FIRST_DW;
reg  [1:0]                                     DEFAULT_ATTR;
reg  [7:0]                                     DEFAULT_TAG;
reg  [3:0]                                     DEFAULT_COMP;
reg  [11:0]                                    EXT_REG_ADDR;
reg                                            TD;
reg                                            EP;
reg  [15:0]                                    VENDOR_ID;
reg  [9:0]                                     LENGTH; // For 1DW config and IO transactions
reg  [6:0]                                     RAND_;
reg  [9:0]                                     CFG_DWADDR;

reg  [15:0]                                    P_DEV_BDF;
reg  [31:0]                                    P_IO_ADDR;
reg  [31:0]                                    P_ADDRESS_1L;
reg  [31:0]                                    P_ADDRESS_2L;
reg  [31:0]                                    P_ADDRESS_3L;
reg  [31:0]                                    P_ADDRESS_4L;
reg  [31:0]                                    P_ADDRESS_H;

reg  [9:0]                                     P_CFG_DWADDR;


event                                          test_begin;
reg  [31:0]                                    P_ADDRESS_MASK;

reg  [31:0]                                    P_READ_DATA; // will store the results of a PCIE read completion
reg  [31:0]                                    data;
reg                                            p_read_data_valid;
reg             [31:0]                         P_WRITE_DATA;
reg  [31:0]                                    temp_register;

// BAR Init variables
reg             [32:0]          BAR_INIT_P_BAR[6:0];           // 6 corresponds to Expansion ROM
                                                                   // note that bit 32 is for overflow checking
reg             [31:0]          BAR_INIT_P_BAR_RANGE[6:0];     // 6 corresponds to Expansion ROM
reg             [1:0]           BAR_INIT_P_BAR_ENABLED[6:0];   // 6 corresponds to Expansion ROM
//                              0 = disabled;  1 = io mapped;  2 = mem32 mapped;  3 = mem64 mapped

reg             [31:0]          BAR_INIT_P_MEM64_HI_START;     // start address for hi memory space
reg             [31:0]          BAR_INIT_P_MEM64_LO_START;     // start address for hi memory space
reg             [32:0]          BAR_INIT_P_MEM32_START;        // start address for low memory space
                                                                   // top bit used for overflow indicator
reg             [32:0]          BAR_INIT_P_IO_START;           // start address for io space
reg             [100:0]         BAR_INIT_MESSAGE[3:0];         // to be used to display info to user

reg             [32:0]          BAR_INIT_TEMP;

reg                             OUT_OF_LO_MEM; // flags to indicate out of mem, mem64, and io
reg                             OUT_OF_IO;
reg                             OUT_OF_HI_MEM;

reg             [3:0]           ii;
integer                         jj;


reg             [31:0]          DEV_VEN_ID;  // holds device and vendor id
integer                         PIO_MAX_NUM_BLOCK_RAMS; // holds the max number of block RAMS
reg             [31:0]          PIO_MAX_MEMORY;
reg             [31:0]          PIO_ADDRESS;     // holds the current PIO testing address

reg                             pio_check_design; // boolean value to check PCI Express BAR configuration against
                                                  // limitations of PIO design. Setting this to true will cause the
                                                  // testbench to check if the core has been configured for more than
                                                  // one IO space, one general purpose Mem32 space (not counting
                                                  // the Mem32 EROM space), and one Mem64 space.

reg                             cpld_to; // boolean value to indicate if time out has occured while waiting for cpld
reg                             cpld_to_finish; // boolean value to indicate to $finish on cpld_to


reg                             verbose; // boolean value to display additional info to stdout

integer                         NUMBER_OF_IO_BARS;
integer                         NUMBER_OF_MEM32_BARS; // Not counting the Mem32 EROM space
integer                         NUMBER_OF_MEM64_BARS;

reg  [9:0]                      RDMA64_TLP_SIZE;
reg  [63:0]                     RDMA64_START_ADDR;

parameter                       Tcq = 1;


/*
 *  DMA Design
 */

// DMA CSR address space (on BAR0)
parameter PCIE_DCSR         = 13'h00; // Device Control Status Register
parameter PCIE_DDMACR       = 13'h04; // Device DMA Control Status Register
parameter PCIE_WDMATLPA     = 13'h08; // Write DMA TLP Address
parameter PCIE_WDMATLPS     = 13'h0C; // Write DMA TLP Size
parameter PCIE_WDMATLPC     = 13'h10; // Write DMA TLP Count
parameter PCIE_WDMATLPP     = 13'h14; // Write DMA Data Pattern
parameter PCIE_RDMATLPP     = 13'h18; // Read DMA Expected Data Pattern
parameter PCIE_RDMATLPA     = 13'h1C; // Read DMA TLP Address
parameter PCIE_RDMATLPS     = 13'h20; // Read DMA TLP Size
parameter PCIE_RDMATLPC     = 13'h24; // Read DMA TLP Count
parameter PCIE_WDMAPERF     = 13'h28; // Write DMA Performance  (RO)
parameter PCIE_RDMAPERF     = 13'h2C; // Read DMA Performance   (RO)
parameter PCIE_RDMASTAT     = 13'h30; // Read DMA Status        (RO)
parameter PCIE_NRDCOMP      = 13'h34; // Number of Read Completion w/ Data (RO)
parameter PCIE_RCOMPDSIZW   = 13'h38; // Read Completion Data Size (RO)
parameter PCIE_DLWSTAT      = 13'h3C; // Device Link Width Status (RO)
parameter PCIE_DLTRSSTAT    = 13'h40; // Device Link Transaction Size Status (RO)
parameter PCIE_DMISCCONT    = 13'h44; // Device Miscellaneous Control

parameter FAI_CFGVAL        = 13'h80; // FAI Configuration Value
parameter WDMASTATUS        = 13'h84;

// DMA Setup Paramenters 
// (Values are assigned in mytest.v)

reg [12:0]  wSize;
reg [15:0]  wCount;
reg [31:0]  u32Pattern;
reg         fEnable64bit;
reg [2:0]   bTrafficClass;
reg [31:0]  LowerAddr;
reg [7:0]   UpperAddr;


// To be used to display info to user
reg [100:0] DMA_CSR_NAME[63:0];

initial
begin
    DMA_CSR_NAME[0] = "DCSR";
    DMA_CSR_NAME[1] = "DDMACR";
    DMA_CSR_NAME[2] = "WDMATLPA";
    DMA_CSR_NAME[3] = "WDMATLPS";
    DMA_CSR_NAME[4] = "WDMATLPC";
    DMA_CSR_NAME[5] = "WDMATLPP";
    DMA_CSR_NAME[6] = "RDMATLPP";
    DMA_CSR_NAME[7] = "RDMATLPA";
    DMA_CSR_NAME[8] = "RDMATLPS";
    DMA_CSR_NAME[9] = "RDMATLPC";
    DMA_CSR_NAME[10] = "WDMAPERF";
    DMA_CSR_NAME[11] = "RDMAPERF";
    DMA_CSR_NAME[12] = "RDMASTAT";
    DMA_CSR_NAME[13] = "NRDCOMP";
    DMA_CSR_NAME[14] = "RCOMPDSIZW";
    DMA_CSR_NAME[15] = "DLWSTAT";
    DMA_CSR_NAME[16] = "DLTRSSTAT";
    DMA_CSR_NAME[17] = "DMISCCONT";
    DMA_CSR_NAME[32] = "FAICFGVAL";
    DMA_CSR_NAME[33] = "WDMASTATUS";

end

/*
 * End of DMA Design
 */

initial
begin

   ADDRESS_32_L         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
   ADDRESS_32_H         = 32'b1011_1110_1110_1111_1100_1010_1111_1110;
   ADDRESS_64           = { ADDRESS_32_H, ADDRESS_32_L };
   COMPLETER_ID         = 16'b0000_0000_1010_0000;
   COMPLETER_ID_CFG     = 16'b0000_0001_1010_0000;
   REQUESTER_ID         = 16'b0000_0001_1010_1111;
   DESTINATION_RID      = 16'b0000_0001_1010_1111;
   DEFAULT_TC           = 3'b000;
   DEFAULT_LENGTH       = 10'h000;
   DEFAULT_BE_LAST_DW   = 4'h0;
   DEFAULT_BE_FIRST_DW  = 4'h0;
   DEFAULT_ATTR         = 2'b01;
   DEFAULT_TAG          = 8'h00;
   DEFAULT_COMP         = 4'h0;
   EXT_REG_ADDR         = 12'h000;
   TD                   = 0;
   EP                   = 0;
   VENDOR_ID            = 16'h10ee;
   LENGTH               = 10'b00_0000_0001;

   RDMA64_TLP_SIZE      = 9'h20;
   RDMA64_START_ADDR    = ADDRESS_64;

end



initial begin
        // Pre-BAR initialization

        BAR_INIT_MESSAGE[0] = "DISABLED";
        BAR_INIT_MESSAGE[1] = "IO MAPPED";
        BAR_INIT_MESSAGE[2] = "MEM32 MAPPED";
        BAR_INIT_MESSAGE[3] = "MEM64 MAPPED";

        OUT_OF_LO_MEM = 1'b0;
        OUT_OF_IO  =    1'b0;
        OUT_OF_HI_MEM = 1'b0;

        // Disable variables to start
        for (ii = 0; ii <= 6; ii = ii + 1) begin
            BAR_INIT_P_BAR[ii] =            33'h00000_0000;
            BAR_INIT_P_BAR_RANGE[ii] =      32'h0000_0000;
            BAR_INIT_P_BAR_ENABLED[ii] =    2'b00;
        end

        BAR_INIT_P_MEM64_HI_START =  32'h0000_0001; // hi 32 bit start of 64bit memory
        BAR_INIT_P_MEM64_LO_START =  32'h0000_0000; // low 32 bit start of 64bit memory
        BAR_INIT_P_MEM32_START =     33'h00000_0000; // start of 32bit memory
        BAR_INIT_P_IO_START      =   33'h00000_0000; // start of 32bit io


        DEV_VEN_ID = (32'h00000007 << 16) | (32'h000010EE);
        PIO_MAX_MEMORY = 8192; // PIO has max of 8Kbytes of memory
        PIO_MAX_NUM_BLOCK_RAMS = 4; // PIO has four block RAMS to test


        PIO_MAX_MEMORY = 2048; // PIO has 4 memory regions with 2 Kbytes of memory per region, ie 8 Kbytes
        PIO_MAX_NUM_BLOCK_RAMS = 4; // PIO has four block RAMS to test

        pio_check_design = 1; //  By default check to make sure the core has been configured
                              //  appropriately for the PIO design

        cpld_to = 0;    // By default time out has not occured
        cpld_to_finish = 1; // By default end simulation on time out


        verbose = 0;  // turned off by default

        NUMBER_OF_IO_BARS =    0;
        NUMBER_OF_MEM32_BARS = 0;
        NUMBER_OF_MEM64_BARS = 0;

end

reg [255:0] testname;
integer test_vars [31:0];
reg [7:0] expect_cpld_payload [4095:0];
reg [7:0] expect_msgd_payload [4095:0];
reg [7:0] expect_memwr_payload [4095:0];
reg [7:0] expect_memwr64_payload [4095:0];
reg [7:0] expect_cfgwr_payload [3:0];
reg expect_status;
reg expect_finish_check;

initial begin
    if ($value$plusargs("TESTNAME=%s", testname))
        $display("Running test {%0s}......", testname);
    else
    begin
        testname = "sample_smoke_test0";
        $display("Running default test {%0s}......", testname);
    end
    expect_status = 0;
    expect_finish_check = 0;
    // Tx transaction interface signal initialization.
    trn_td     = 0;
    trn_tsof_n = 1;
    trn_teof_n = 1;
    trn_trem_n = 0;
    trn_terrfwd_n = 1;
    trn_tsrc_rdy_n = 1 ;
    trn_tsrc_dsc_n = 1;

    // Payload data initialization.
    TSK_USR_DATA_SETUP_SEQ;

    //Test starts here
    if (testname == "dummy_test") begin
        $display("[%t] %m: Invalid TESTNAME: %0s", $realtime, testname);
        $finish(2);
    end

    `include "tests.v"

    else begin
        $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
        $finish(2);
    end
end

  task TSK_SYSTEM_INITIALIZATION;
  begin
    //--------------------------------------------------------------------------
    // Event # 1: Wait for Transaction reset to be de-asserted..
    //--------------------------------------------------------------------------

    wait (trn_reset_n == 1);

    $display("[%t] : Transaction Reset Is De-asserted...", $realtime);


    //--------------------------------------------------------------------------
    // Event # 2: Wait for Transaction link to be asserted..
    //--------------------------------------------------------------------------

    wait (trn_lnk_up_n == 0);

    $display("[%t] : Transaction Link Is Up...", $realtime);


  end
  endtask

/************************************************************
Task : TSK_TX_TYPE0_CONFIGURATION_READ
Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
Outputs : Transaction Tx Interface Signaling
Description : Generates a Type 0 Configuration Read TLP
*************************************************************/

task TSK_TX_TYPE0_CONFIGURATION_READ;
    input    [7:0]    tag_;
    input    [11:0]    reg_addr_;
    input    [3:0]    first_dw_be_;
    begin
        if (trn_lnk_up_n) begin

            $display("[%t] : Trn interface is MIA", $realtime);
            $finish(1);

        end

        TSK_TX_SYNCHRONIZE(0, 0);

        trn_td             <= #(Tcq)    {
                                        1'b0,
                                        2'b00,
                                        5'b00100,
                                        1'b0,
                                        3'b000,
                                        4'b0000,
                                        1'b0,
                                        1'b0,
                                        2'b00,
                                        2'b00,
                                        10'b0000000001,  // 32
                                        COMPLETER_ID_CFG,
                                        tag_,
                                        4'b0000,
                                        first_dw_be_     // 64
                                        };

        trn_tsof_n         <= #(Tcq)    0;
        trn_teof_n         <= #(Tcq)    1;
        trn_trem_n         <= #(Tcq)    0;
        trn_tsrc_rdy_n     <= #(Tcq)    0 ;

        TSK_TX_SYNCHRONIZE(1, 0);

        trn_td             <= #(Tcq)    {
                                        COMPLETER_ID_CFG,
                                        4'b0000,
                                        reg_addr_[11:2],
                                        2'b00,
                                        32'b0
                                        };

        trn_tsof_n         <= #(Tcq)    1;
        trn_teof_n         <= #(Tcq)    0;
        trn_trem_n         <= #(Tcq)    8'h0F;
        trn_tsrc_rdy_n     <= #(Tcq)    0 ;

        TSK_TX_SYNCHRONIZE(1, 1);

        trn_teof_n         <= #(Tcq)    1;
        trn_trem_n         <= #(Tcq)    0;
        trn_tsrc_rdy_n     <= #(Tcq)    1;

    end
endtask // TSK_TX_TYPE0_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_READ;
        input    [7:0]    tag_;
        input    [11:0]    reg_addr_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b00,
                                            5'b00101,
                                            1'b0,
                                            3'b000,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            10'b0000000001,  // 32
                                            COMPLETER_ID_CFG,
                                            tag_,
                                            4'b0000,
                                            first_dw_be_     // 64
                                            };

            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)    {
                                            COMPLETER_ID_CFG,
                                            4'b0000,
                                            reg_addr_[11:2],
                                            2'b00,
                                            32'b0
                                            };

            trn_tsof_n         <= #(Tcq)    1;
            trn_teof_n         <= #(Tcq)    0;
            trn_trem_n         <= #(Tcq)    8'h0F;
            trn_tsrc_rdy_n     <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    1;

        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_READ

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_WRITE;
        input    [7:0]    tag_;
        input    [11:0]    reg_addr_;
        input    [31:0]    reg_data_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)   {
                                           1'b0,
                                           2'b10,
                                           5'b00100,
                                           1'b0,
                                           3'b000,
                                           4'b0000,
                                           1'b0,
                                           1'b0,
                                           2'b00,
                                           2'b00,
                                           10'b0000000001, // 32
                                           COMPLETER_ID_CFG,
                                           tag_,
                                           4'b0000,
                                           first_dw_be_    // 64
                                           };

            trn_tsof_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)   {
                                           COMPLETER_ID_CFG,
                                           4'b0000,
                                           reg_addr_[11:2],
                                           2'b00,            // 32
                                           reg_data_[7:0],
                                           reg_data_[15:8],
                                           reg_data_[23:16],
                                           reg_data_[31:24]  // 64
                                           };

            trn_tsof_n         <= #(Tcq)   1;
            trn_teof_n         <= #(Tcq)   0;
            trn_trem_n         <= #(Tcq)   8'h00;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)   1;
            trn_trem_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   1;

        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_TYPE1_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 1 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE1_CONFIGURATION_WRITE;
        input    [7:0]    tag_;
        input    [11:0]    reg_addr_;
        input    [31:0]    reg_data_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)   {
                                           1'b0,
                                           2'b10,
                                           5'b00101,
                                           1'b0,
                                           3'b000,
                                           4'b0000,
                                           1'b0,
                                           1'b0,
                                           2'b00,
                                           2'b00,
                                           10'b0000000001, // 32
                                           COMPLETER_ID_CFG,
                                           tag_,
                                           4'b0000,
                                           first_dw_be_    // 64
                                           };

            trn_tsof_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)   {
                                           COMPLETER_ID_CFG,
                                           4'b0000,
                                           reg_addr_[11:2],
                                           2'b00,            // 32
                                           reg_data_[7:0],
                                           reg_data_[15:8],
                                           reg_data_[23:16],
                                           reg_data_[31:24]  // 64
                                           };

            trn_tsof_n         <= #(Tcq)   1;
            trn_teof_n         <= #(Tcq)   0;
            trn_trem_n         <= #(Tcq)   8'h00;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)   1;
            trn_trem_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   1;

        end
    endtask // TSK_TX_TYPE1_CONFIGURATION_WRITE

    /************************************************************
    Task : TSK_TX_MEMORY_READ_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_32;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [31:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)  {
                                          1'b0,
                                          2'b00,
                                          5'b00000,
                                          1'b0,
                                          tc_,
                                          4'b0000,
                                          1'b0,
                                          1'b0,
                                          2'b00,
                                          2'b00,
                                          len_,         // 32
                                          COMPLETER_ID_CFG,
                                          tag_,
                                          last_dw_be_,
                                          first_dw_be_  // 64
                                          };
            trn_tsof_n         <= #(Tcq)  0;
            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)  {
                                          addr_[31:2],
                                          2'b00,
                                          32'b0
                                          };

            trn_tsof_n         <= #(Tcq)  1;
            trn_teof_n         <= #(Tcq)  0;
            trn_trem_n         <= #(Tcq)  8'h0F;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  1;

        end
    endtask // TSK_TX_MEMORY_READ_32

    /************************************************************
    Task : TSK_TX_MEMORY_READ_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_64;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)  {
                                          1'b0,
                                          2'b01,
                                          5'b00000,
                                          1'b0,
                                          tc_,
                                          4'b0000,
                                          1'b0,
                                          1'b0,
                                          2'b00,
                                          2'b00,
                                          len_,         // 32
                                          COMPLETER_ID_CFG,
                                          tag_,
                                          last_dw_be_,
                                          first_dw_be_  // 64
                                          };
            trn_tsof_n         <= #(Tcq)  0;
            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)  {
                                          addr_[63:2],
                                          2'b00
                                          };

            trn_tsof_n         <= #(Tcq)  1;
            trn_teof_n         <= #(Tcq)  0;
            trn_trem_n         <= #(Tcq)  8'h00;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  1;

        end
    endtask // TSK_TX_MEMORY_READ_64

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_32;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [31:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        input        ep_;
        reg    [10:0]    _len;
        integer        _j;
        begin

            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)  {
                                          1'b0,
                                          2'b10,
                                          5'b00000,
                                          1'b0,
                                          tc_,
                                          4'b0000,
                                          1'b0,
                                          1'b0,
                                          2'b00,
                                          2'b00,
                                          len_,        // 32
                                          COMPLETER_ID_CFG,
                                          tag_,
                                          last_dw_be_,
                                          first_dw_be_ // 64
                                          };
            trn_tsof_n         <= #(Tcq)  0;
            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)   {
                                          addr_[31:2],
                                          2'b00,
                                          DATA_STORE[0],
                                          DATA_STORE[1],
                                          DATA_STORE[2],
                                          DATA_STORE[3]
                                          };

            trn_tsof_n         <= #(Tcq)  1;

            if (_len != 1) begin

                for (_j = 4; _j < (_len * 4); _j = _j + 8) begin

                    TSK_TX_SYNCHRONIZE(1, 0);

                    trn_td <= #(Tcq)    {
                                DATA_STORE[_j + 0],
                                DATA_STORE[_j + 1],
                                DATA_STORE[_j + 2],
                                DATA_STORE[_j + 3],
                                DATA_STORE[_j + 4],
                                DATA_STORE[_j + 5],
                                DATA_STORE[_j + 6],
                                DATA_STORE[_j + 7]
                                };


                    if ((_j + 7)  >=  ((_len * 4) - 1)) begin

                        trn_teof_n         <= #(Tcq) 0;
                        if (ep_)
                            trn_terrfwd_n     <= #(Tcq) 0;

                        if (((_len - 1) % 2) == 0)

                            trn_trem_n     <= #(Tcq) 8'h00;

                        else

                            trn_trem_n     <= #(Tcq) 8'h0f;

                    end

                end

            end else begin

                trn_teof_n         <= #(Tcq) 0;
                if (ep_)
                    trn_terrfwd_n     <= #(Tcq) 0;
                trn_trem_n         <= #(Tcq) 8'h00;

            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_terrfwd_n      <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;

        end
    endtask // TSK_TX_MEMORY_WRITE_32

    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_64
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 64 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_64;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        input        ep_;
        reg    [10:0]    _len;
        integer        _j;
        begin

            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq) {
                                         1'b0,
                                         2'b11,
                                         5'b00000,
                                         1'b0,
                                         tc_,
                                         4'b0000,
                                         1'b0,
                                         1'b0,
                                         2'b00,
                                         2'b00,
                                         len_,        // 32
                                         COMPLETER_ID_CFG,
                                         tag_,
                                         last_dw_be_,
                                         first_dw_be_ // 64
                                         };
            trn_tsof_n         <= #(Tcq) 0;
            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                addr_[63:2],
                                2'b00
                                };
            trn_tsof_n         <= #(Tcq) 1;

            for (_j = 0; _j < (_len * 4); _j = _j + 8) begin

                TSK_TX_SYNCHRONIZE(1, 0);

                trn_td <= #(Tcq)    {
                            DATA_STORE[_j + 0],
                            DATA_STORE[_j + 1],
                            DATA_STORE[_j + 2],
                            DATA_STORE[_j + 3],
                            DATA_STORE[_j + 4],
                            DATA_STORE[_j + 5],
                            DATA_STORE[_j + 6],
                            DATA_STORE[_j + 7]
                            };

                if ((_j + 7)  >= ((_len * 4) - 1)) begin
                    trn_teof_n         <= #(Tcq) 0;
                    if (ep_)
                        trn_terrfwd_n     <= #(Tcq) 0;

                    if ((_len % 2) == 0)
                        trn_trem_n     <= #(Tcq) 8'h00;
                    else
                        trn_trem_n     <= #(Tcq) 8'h0f;
                end
            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_terrfwd_n      <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;

        end
    endtask // TSK_TX_MEMORY_WRITE_64

    /************************************************************
    Task : TSK_TX_COMPLETION
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [2:0]    comp_status_;
        begin

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b00,
                                            5'b01010,
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            COMPLETER_ID_CFG,
                                            comp_status_,
                                            1'b0,
                                            12'b0
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                COMPLETER_ID_CFG,
                                tag_,
                                8'b00,
                                32'b0
                                };
            trn_tsof_n         <= #(Tcq) 1;
            trn_teof_n         <= #(Tcq) 0;
            trn_trem_n         <= #(Tcq) 8'h0F;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
               trn_tsrc_rdy_n         <= #(Tcq) 1;

        end
    endtask // TSK_TX_COMPLETION

    /************************************************************
    Task : TSK_TX_COMPLETION_DATA
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION_DATA;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input   [11:0]  byte_count_;
        input   [6:0]   lower_addr_;
        input    [2:0]    comp_status_;
        input        ep_;
        reg    [10:0]    _len;
        integer        _j;
        begin
            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b10,
                                            5'b01010,
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            COMPLETER_ID_CFG,
                                            comp_status_,
                                            1'b0,
                                            byte_count_    // 64
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                COMPLETER_ID_CFG,
                                tag_,
                                1'b0,
                                lower_addr_,
                                DATA_STORE[0],
                                DATA_STORE[1],
                                DATA_STORE[2],
                                DATA_STORE[3]
                                };
            trn_tsof_n         <= #(Tcq) 1;

            if (_len != 1) begin

                for (_j = 4; _j < (_len * 4); _j = _j + 8) begin

                    TSK_TX_SYNCHRONIZE(1, 0);

                    trn_td <= #(Tcq)    {
                                DATA_STORE[_j + 0],
                                DATA_STORE[_j + 1],
                                DATA_STORE[_j + 2],
                                DATA_STORE[_j + 3],
                                DATA_STORE[_j + 4],
                                DATA_STORE[_j + 5],
                                DATA_STORE[_j + 6],
                                DATA_STORE[_j + 7]
                                };


                    if ((_j + 7)  >=  ((_len * 4) - 1)) begin

                        trn_teof_n         <= #(Tcq) 0;

                        if (ep_)
                            trn_terrfwd_n     <= #(Tcq) 0;

                        if (((_len - 1) % 2) == 0)

                            trn_trem_n     <= #(Tcq) 8'h00;

                        else

                            trn_trem_n     <= #(Tcq) 8'h0f;

                    end

                end

            end else begin

                trn_teof_n         <= #(Tcq) 0;
                trn_trem_n         <= #(Tcq) 8'h00;

            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_terrfwd_n      <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;

        end
    endtask // TSK_TX_COMPLETION_DATA

    /************************************************************
    Task : TSK_TX_MESSAGE
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message TLP
    *************************************************************/

    task TSK_TX_MESSAGE;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]    data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        begin

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b01,
                                            {{2'b10}, {message_rtg_}},
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            10'b0,        // 32
                                            COMPLETER_ID_CFG,
                                            tag_,
                                            message_code_ // 64
                                            };

            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                data_
                                };
            trn_tsof_n         <= #(Tcq) 1;
            trn_teof_n         <= #(Tcq) 0;
            trn_trem_n         <= #(Tcq) 8'h00;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
               trn_tsrc_rdy_n         <= #(Tcq) 1;

        end
    endtask // TSK_TX_MESSAGE

    /************************************************************
    Task : TSK_TX_MESSAGE_DATA
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message Data TLP
    *************************************************************/

    task TSK_TX_MESSAGE_DATA;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]    data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        reg    [10:0]    _len;
        integer     _j;
        begin

            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b11,
                                            {{2'b10}, {message_rtg_}},
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            COMPLETER_ID_CFG,
                                            tag_,
                                            message_code_   // 64
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                data_
                                };
            trn_tsof_n         <= #(Tcq) 1;

            for (_j = 0; _j < (_len * 4); _j = _j + 8) begin

                TSK_TX_SYNCHRONIZE(1, 0);

                trn_td <= #(Tcq)    {
                            DATA_STORE[_j + 0],
                            DATA_STORE[_j + 1],
                            DATA_STORE[_j + 2],
                            DATA_STORE[_j + 3],
                            DATA_STORE[_j + 4],
                            DATA_STORE[_j + 5],
                            DATA_STORE[_j + 6],
                            DATA_STORE[_j + 7]
                            };


                if ((_j + 7)  >= ((_len * 4) - 1)) begin

                    trn_teof_n         <= #(Tcq) 0;

                    if ((_len % 2) == 0)

                        trn_trem_n     <= #(Tcq) 8'h00;
                    else

                        trn_trem_n     <= #(Tcq) 8'h0f;
                end

            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
               trn_tsrc_rdy_n         <= #(Tcq) 1;

        end
    endtask // TSK_TX_MESSAGE_DATA


    /************************************************************
    Task : TSK_TX_IO_READ
    Inputs : Tag, Address
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Read TLP
    *************************************************************/

    task TSK_TX_IO_READ;
        input    [7:0]    tag_;
        input    [31:0]    addr_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)   {
                                           1'b0,
                                           2'b00,
                                           5'b00010,
                                           1'b0,
                                           3'b000,
                                           4'b0000,
                                           1'b0,
                                           1'b0,
                                           2'b00,
                                           2'b00,
                                           10'b1,         // 32
                                           COMPLETER_ID_CFG,
                                           tag_,
                                           4'b0,
                                           first_dw_be_  // 64
                                           };
            trn_tsof_n         <= #(Tcq)   0;
            trn_teof_n         <= #(Tcq)   1;
            trn_trem_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)    {
                                            addr_[31:2],
                                            2'b00,
                                            32'b0
                                            };
            trn_tsof_n         <= #(Tcq)    1;
            trn_teof_n         <= #(Tcq)    0;
            trn_trem_n         <= #(Tcq)    8'h0F;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    1;

        end
    endtask // TSK_TX_IO_READ

    /************************************************************
    Task : TSK_TX_IO_WRITE
    Inputs : Tag, Address, Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a IO Read TLP
    *************************************************************/

    task TSK_TX_IO_WRITE;
        input    [7:0]    tag_;
        input    [31:0]    addr_;
        input    [3:0]    first_dw_be_;
        input     [31:0]    data_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b10,
                                            5'b00010,
                                            1'b0,
                                            3'b000,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            10'b1,         // 32
                                            COMPLETER_ID_CFG,
                                            tag_,
                                            4'b0,
                                            first_dw_be_  // 64
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)    {
                                            addr_[31:2],
                                            2'b00,
                                            data_[7:0],
                                            data_[15:8],
                                            data_[23:16],
                                            data_[31:24]
                                            };
            trn_tsof_n         <= #(Tcq)    1;
            trn_teof_n         <= #(Tcq)    0;
            trn_trem_n         <= #(Tcq)    8'h00;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    1;

        end
    endtask // TSK_TX_IO_WRITE

/************************************************************
Task : TSK_TX_SYNCHRONIZE
Inputs : None
Outputs : None
Description : Synchronize with tx clock and handshake signals
*************************************************************/

task TSK_TX_SYNCHRONIZE;

    input   first_;
    input   last_call_;

    reg     last_;

    begin
        if (trn_lnk_up_n) begin
            $display("[%t] : Trn interface is MIA", $realtime);
            $finish(1);
        end

        @(posedge trn_clk);
        if ((trn_tdst_rdy_n == 1'b1) && (first_ == 1'b1)) begin
            while (trn_tdst_rdy_n == 1'b1) begin
                @(posedge trn_clk);
            end
        end
        if (first_ == 1'b1) begin
            last_ = (trn_trem_n == 8'h00) ? 0 : 1;
            // read data driven into memory
            board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_READ_DATA(last_,
                                                                        `TX_LOG,
                                                                        trn_td,
                                                                        trn_trem_n);
        end

        if (last_call_)
             board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_PARSE_FRAME(`TX_LOG);
    end
endtask // TSK_TX_SYNCHRONIZE


    /************************************************************
    Task : TSK_USR_DATA_SETUP_SEQ
    Inputs : None
    Outputs : None
    Description : Populates scratch pad data area with known good data.
    *************************************************************/

    task TSK_USR_DATA_SETUP_SEQ;
        integer        i_;
        begin
            for (i_ = 0; i_ <= 4095; i_ = i_ + 1) begin
                DATA_STORE[i_] = i_;
            end
        end
    endtask // TSK_USR_DATA_SETUP_SEQ

    /************************************************************
    Task : TSK_TX_CLK_EAT
    Inputs : None
    Outputs : None
    Description : Consume clocks.
    *************************************************************/

    task TSK_TX_CLK_EAT;
        input    [31:0]            clock_count;
        integer            i_;
        begin
            for (i_ = 0; i_ < clock_count; i_ = i_ + 1) begin

                @(posedge trn_clk);

            end
        end
    endtask // TSK_TX_CLK_EAT

  /************************************************************
  Task: TSK_SIMULATION_TIMEOUT
  Description: Set simulation timeout value
  *************************************************************/
  task TSK_SIMULATION_TIMEOUT;
    input [31:0] timeout;
    begin
      force board.xilinx_pci_exp_4_lane_downstream_port.rx_usrapp.sim_timeout = timeout;
    end
  endtask



    /************************************************************
    Task : TSK_TX_BAR_READ
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32,64 or IO Read TLP
                  requesting 1 dword
    *************************************************************/

    task TSK_TX_BAR_READ;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;


        begin


          case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin
              if (verbose) $display("[%t] : IOREAD, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));

                          TSK_TX_IO_READ(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF);
                end

        2'b10 : // MEM 32 SPACE
            begin

  if (verbose) $display("[%t] : MEMREAD32, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
                           TSK_TX_MEMORY_READ_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF);
                end
        2'b11 : // MEM 64 SPACE
                begin
                   if (verbose) $display("[%t] : MEMREAD64, address = %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset));
               TSK_TX_MEMORY_READ_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[ii+1][31:0],
                                    BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF);


                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_READ");
                  end
      endcase

        end
    endtask // TSK_TX_BAR_READ



    /************************************************************
    Task : TSK_TX_BAR_WRITE
    Inputs : Bar Index, Byte Offset, Tag, Tc, 32 bit Data
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32, 64, IO TLP with
                  32 bit data
    *************************************************************/

    task TSK_TX_BAR_WRITE;

        input    [2:0]    bar_index;
        input    [31:0]   byte_offset;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [31:0]   data_;

        begin

        case(BAR_INIT_P_BAR_ENABLED[bar_index])
        2'b01 : // IO SPACE
            begin

              if (verbose) $display("[%t] : IOWRITE, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                          TSK_TX_IO_WRITE(tag_, BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'hF, data_);

                end

        2'b10 : // MEM 32 SPACE
            begin

               DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
               if (verbose) $display("[%t] : MEMWRITE32, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_32(tag_, tc_, 10'd1,
                                                  BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), 4'h0, 4'hF, 1'b0);

                end
        2'b11 : // MEM 64 SPACE
                begin

                   DATA_STORE[0] = data_[7:0];
                           DATA_STORE[1] = data_[15:8];
                           DATA_STORE[2] = data_[23:16];
                           DATA_STORE[3] = data_[31:24];
                   if (verbose) $display("[%t] : MEMWRITE64, address = %x, Write Data %x", $realtime,
                                   BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset), data_);
                   TSK_TX_MEMORY_WRITE_64(tag_, tc_, 10'd1, {BAR_INIT_P_BAR[bar_index+1][31:0],
                                      BAR_INIT_P_BAR[bar_index][31:0]+(byte_offset)}, 4'h0, 4'hF, 1'b0);



                    end
        default : begin
                    $display("Error case in task TSK_TX_BAR_WRITE");
                  end
    endcase


        end
    endtask // TSK_TX_BAR_WRITE




/************************************************************
Task : TSK_SET_READ_DATA
Inputs : Data
Outputs : None
Description : Called from common app. Common app hands read
              data to usrapp_tx.
*************************************************************/

task TSK_SET_READ_DATA;

    input   [3:0]   be_;   // not implementing be's yet
    input   [31:0]  data_; // might need to change this to byte
    begin
        P_READ_DATA = data_;
        p_read_data_valid = 1;
    end
endtask // TSK_SET_READ_DATA


/************************************************************
Task : TSK_WAIT_FOR_READ_DATA
Inputs : None
Outputs : Read data P_READ_DATA will be valid
Description : Called from tx app. Common app hands read
              data to usrapp_tx. This task must be executed
              immediately following a call to
              TSK_TX_TYPE0_CONFIGURATION_READ in order for the
              read process to function correctly. Otherwise
              there is a potential race condition with
              p_read_data_valid.
*************************************************************/

task TSK_WAIT_FOR_READ_DATA;

    integer j;
    begin
        j = 10;
        p_read_data_valid = 0;
        fork
        while ((!p_read_data_valid) && (cpld_to == 0)) @(posedge trn_clk); 

        begin // second process
            while ((j > 0) && (!p_read_data_valid)) begin
                TSK_TX_CLK_EAT(100);
                j = j - 1;
            end

            if (!p_read_data_valid) begin
                cpld_to = 1; 
                if (cpld_to_finish == 1) begin 
                    $display("TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");
                    $finish;
                end
                else
                    $display("TIMEOUT WARNING in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");

              end
          end
          join
    end
endtask // TSK_WAIT_FOR_READ_DATA




    /************************************************************
    Function : TSK_DISPLAY_PCIE_MAP
    Inputs : none
    Outputs : none
    Description : Displays the Memory Manager's P_MAP calculations
                  based on range values read from PCI_E device.
    *************************************************************/

        task TSK_DISPLAY_PCIE_MAP;

           reg[2:0] ii;

           begin

             for (ii=0; ii <= 6; ii = ii + 1) begin
                 if (ii !=6) begin

                   $display("\tBAR %x: VALUE = %x RANGE = %x TYPE = %s", ii, BAR_INIT_P_BAR[ii][31:0],
                     BAR_INIT_P_BAR_RANGE[ii], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[ii]]);

                 end
                 else begin

                   $display("\tEROM : VALUE = %x RANGE = %x TYPE = %s", BAR_INIT_P_BAR[6][31:0],
                     BAR_INIT_P_BAR_RANGE[6], BAR_INIT_MESSAGE[BAR_INIT_P_BAR_ENABLED[6]]);

                 end
             end

           end

        endtask



    /************************************************************
    Task : TSK_BUILD_PCIE_MAP
    Inputs :
    Outputs :
    Description : Looks at range values read from config space and
                  builds corresponding mem/io map
    *************************************************************/

    task TSK_BUILD_PCIE_MAP;

                integer ii;

        begin

                  $display("[%t] PCI EXPRESS BAR MEMORY/IO MAPPING PROCESS BEGUN...",$realtime);

              // handle bars 0-6 (including erom)
              for (ii = 0; ii <= 6; ii = ii + 1) begin

                  if (BAR_INIT_P_BAR_RANGE[ii] != 32'h0000_0000) begin

                     if ((ii != 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) begin // if not erom and io bit set

                        // bar is io mapped
                        NUMBER_OF_IO_BARS = NUMBER_OF_IO_BARS + 1;

                        if (pio_check_design && (NUMBER_OF_IO_BARS > 1)) begin

                          $display("[%t] Warning: PIO design only supports 1 IO BAR. Testbench will disable BAR %x",$realtime, ii);
                          BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                        end

                        else BAR_INIT_P_BAR_ENABLED[ii] = 2'h1;

                        if (!OUT_OF_IO) begin

                           // We need to calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_IO_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                  if (BAR_INIT_TEMP < BAR_INIT_P_IO_START) begin
                                     // Current BAR_INIT_P_IO_START is NOT correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                      BAR_INIT_P_IO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current BAR_INIT_P_IO_START is correct start for new base
                                      BAR_INIT_P_BAR[ii] = BAR_INIT_P_IO_START;
                                      BAR_INIT_P_IO_START = BAR_INIT_P_IO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                                  OUT_OF_IO = BAR_INIT_P_BAR[ii][32];

                              if (OUT_OF_IO) begin

                                 $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                              end

                        end
                          else begin

                               $display("\tOut of PCI EXPRESS IO SPACE due to BAR %x", ii);

                          end



                     end // bar is io mapped

                     else begin

                        // bar is mem mapped
                        if ((ii != 5) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0004)) begin

                           // bar is mem64 mapped - memManager is not handling out of 64bit memory
                               NUMBER_OF_MEM64_BARS = NUMBER_OF_MEM64_BARS + 1;

                               if (pio_check_design && (NUMBER_OF_MEM64_BARS > 1)) begin

                              $display("[%t] Warning: PIO design only supports 1 MEM64 BAR. Testbench will disable BAR %x",$realtime, ii);
                              BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                           end

                           else BAR_INIT_P_BAR_ENABLED[ii] = 2'h3; // bar is mem64 mapped


                           if ( (BAR_INIT_P_BAR_RANGE[ii] & 32'hFFFF_FFF0) == 32'h0000_0000) begin

                              // Mem64 space has range larger than 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_HI_START & BAR_INIT_P_BAR_RANGE[ii+1];

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_HI_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_BAR[ii+1] + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);
                                     BAR_INIT_P_MEM64_LO_START = 32'h0000_0000;

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        32'h0000_0000;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_HI_START = BAR_INIT_P_MEM64_HI_START + FNC_CONVERT_RANGE_TO_SIZE_HI32(ii+1);

                                  end

                           end
                           else begin

                              // Mem64 space has range less than/equal 2 Gigabytes

                              // calculate where the next BAR should start based on the BAR's range
                                  BAR_INIT_TEMP = BAR_INIT_P_MEM64_LO_START & (BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0);

                                  if (BAR_INIT_TEMP < BAR_INIT_P_MEM64_LO_START) begin

                                     // Current MEM32_START is NOT correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end
                                  else begin

                                     // Initial BAR case and Current MEM32_START is correct start for new base
                                     BAR_INIT_P_BAR[ii] =        BAR_INIT_P_MEM64_LO_START;
                                     BAR_INIT_P_BAR[ii+1] =      BAR_INIT_P_MEM64_HI_START;
                                     BAR_INIT_P_MEM64_LO_START = BAR_INIT_P_MEM64_LO_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                  end

                           end

                              // skip over the next bar since it is being used by the 64bit bar
                              ii = ii + 1;

                        end
                        else begin

                           if ( (ii != 6) || ((ii == 6) && (BAR_INIT_P_BAR_RANGE[ii] & 32'h0000_0001)) ) begin
                              // handling general mem32 case and erom case

                              // bar is mem32 mapped
                              if (ii != 6) begin

                                 NUMBER_OF_MEM32_BARS = NUMBER_OF_MEM32_BARS + 1; // not counting erom space

                                 if (pio_check_design && (NUMBER_OF_MEM32_BARS > 1)) begin

                                    // PIO design only supports 1 general purpose MEM32 BAR (not including EROM).
                                    $display("[%t] Warning: PIO design only supports 1 MEM32 BAR. Testbench will disable BAR %x",$realtime, ii);
                                    BAR_INIT_P_BAR_ENABLED[ii] = 2'h0; // disable BAR

                                 end

                                 else  BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // bar is mem32 mapped

                              end

                              else BAR_INIT_P_BAR_ENABLED[ii] = 2'h2; // erom bar is mem32 mapped

                              if (!OUT_OF_LO_MEM) begin

                                     // We need to calculate where the next BAR should start based on the BAR's range
                                     BAR_INIT_TEMP = BAR_INIT_P_MEM32_START & {1'b1,(BAR_INIT_P_BAR_RANGE[ii] & 32'hffff_fff0)};

                                     if (BAR_INIT_TEMP < BAR_INIT_P_MEM32_START) begin

                                         // Current MEM32_START is NOT correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_TEMP + FNC_CONVERT_RANGE_TO_SIZE_32(ii);
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_BAR[ii] + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end
                                     else begin

                                         // Initial BAR case and Current MEM32_START is correct start for new base
                                         BAR_INIT_P_BAR[ii] =     BAR_INIT_P_MEM32_START;
                                         BAR_INIT_P_MEM32_START = BAR_INIT_P_MEM32_START + FNC_CONVERT_RANGE_TO_SIZE_32(ii);

                                     end


     if (ii == 6) begin

        // make sure to set enable bit if we are mapping the erom space

        BAR_INIT_P_BAR[ii] = BAR_INIT_P_BAR[ii] | 33'h1;


     end


                                 OUT_OF_LO_MEM = BAR_INIT_P_BAR[ii][32];

                                 if (OUT_OF_LO_MEM) begin

                                    $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                                 end

                              end
                              else begin

                                     $display("\tOut of PCI EXPRESS MEMORY 32 SPACE due to BAR %x", ii);

                              end

                           end

                        end

                     end

                  end

              end


                  if ( (OUT_OF_IO) | (OUT_OF_LO_MEM) | (OUT_OF_HI_MEM)) begin
                     TSK_DISPLAY_PCIE_MAP;
                     $display("ERROR: Ending simulation: Memory Manager is out of memory/IO to allocate to PCI Express device");
                     $finish;

                  end


        end

    endtask // TSK_BUILD_PCIE_MAP


/************************************************************
    Task : TSK_BAR_SCAN
    Inputs : None
    Outputs : None
    Description : Scans PCI core's configuration registers.
*************************************************************/

task TSK_BAR_SCAN;
    begin

    //--------------------------------------------------------------------------
    // Write PCI_MASK to bar's space via PCIe fabric interface to find range
    //--------------------------------------------------------------------------

    P_ADDRESS_MASK  = 32'hffff_ffff;
    DEFAULT_TAG     = 0;
    DEFAULT_TC      = 0;

    $display("[%t] : Inspecting Core Configuration Space...", $realtime);

    // Determine Range for BAR0
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR0 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[0] = P_READ_DATA;

    // Determine Range for BAR1
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR1 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[1] = P_READ_DATA;

    // Determine Range for BAR2
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR2 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[2] = P_READ_DATA;

    // Determine Range for BAR3
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR3 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[3] = P_READ_DATA;

    // Determine Range for BAR4
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR4 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[4] = P_READ_DATA;

    // Determine Range for BAR5
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR5 Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[5] = P_READ_DATA;

    // Determine Range for Expansion ROM BAR
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, P_ADDRESS_MASK, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR Range
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_WAIT_FOR_READ_DATA;
    BAR_INIT_P_BAR_RANGE[6] = P_READ_DATA;

    end
endtask // TSK_BAR_SCAN


/************************************************************
    Task : TSK_BAR_PROGRAM
    Inputs : None
    Outputs : None
    Description : Program's PCI core's configuration registers.
*************************************************************/

task TSK_BAR_PROGRAM;
   begin

    //-----------------------------------------------------------------------
    // Write core configuration space via PCIe fabric interface
    //----------------------------------------------------------------------
    DEFAULT_TAG     = 0;
    P_DEV_BDF       = 16'h00_0_0;

    $display("[%t] : Setting Core Configuration Space...", $realtime);

    // Program BAR0
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, BAR_INIT_P_BAR[0][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program BAR1
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, BAR_INIT_P_BAR[1][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program BAR2
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, BAR_INIT_P_BAR[2][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program BAR3
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h1C, BAR_INIT_P_BAR[3][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program BAR4
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, BAR_INIT_P_BAR[4][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program BAR5
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h24, BAR_INIT_P_BAR[5][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program Expansion ROM BAR
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h30, BAR_INIT_P_BAR[6][31:0], 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program PCI Command Register
    // Enable Bus Master
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h04, 32'h00000007, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program PCIe Device Control Register
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h60, 32'h0000005f, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Program MSI Capability Register Set
    // Enable MSI
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h48, 32'h00010000, 4'b0100);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

   end
endtask // TSK_BAR_PROGRAM


/************************************************************
     Task : TSK_BAR_INIT
     Inputs : None
     Outputs : None
     Description : Initialize PCI core based on core's configuration.
*************************************************************/
task TSK_BAR_INIT;
   begin

    TSK_BAR_SCAN;

    TSK_BUILD_PCIE_MAP;

    TSK_DISPLAY_PCIE_MAP;

    TSK_BAR_PROGRAM;

   end
endtask // TSK_BAR_INIT


/************************************************************
     Task : TSK_TX_READBACK_CONFIG
     Inputs : None
     Outputs : None
     Description : Read core configuration space via PCIe fabric interface
*************************************************************/

task TSK_TX_READBACK_CONFIG;
    begin

    //--------------------------------------------------------------------------
    // Read core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------
    $display("[%t] : Reading Core Configuration Space...", $realtime);

    // Read BAR0
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR1
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR2
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR3
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h1C, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR4
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read BAR5
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h24, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read Expansion ROM BAR
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h30, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read PCI Command Register
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h04, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read PCIe Device Control Register
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h60, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(1000);

    end
endtask // TSK_TX_READBACK_CONFIG


/************************************************************
     Task : TSK_CFG_READBACK_CONFIG
     Inputs : None
     Outputs : None
     Description : Read core configuration space via CFG interface
*************************************************************/

task TSK_CFG_READBACK_CONFIG;
   begin

//--------------------------------------------------------------------------
// Read core configuration space via configuration (host) interface
//--------------------------------------------------------------------------

    $display("[%t] : Reading Local Configuration Space via CFG interface...", $realtime);

    CFG_DWADDR = 10'h0;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h4;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h5;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h6;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h7;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h8;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h9;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'hc;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h17;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h18;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h19;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

    CFG_DWADDR = 10'h1a;
    board.xilinx_pci_exp_4_lane_downstream_port.cfg_usrapp.TSK_READ_CFG_DW(CFG_DWADDR);

      end
    endtask // TSK_CFG_READBACK_CONFIG



/************************************************************
        Task : TSK_MEM_TEST_DATA_BUS
        Inputs : bar_index
        Outputs : None
        Description : Test the data bus wiring in a specific memory
               by executing a walking 1's test at a set address
               within that region.
*************************************************************/

task TSK_MEM_TEST_DATA_BUS;
   input [2:0]  bar_index;
   reg [31:0] pattern;
   reg success;
   begin

    $display("[%t] : Performing Memory data test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    // Perform a walking 1's test at the given address.
    for (pattern = 1; pattern != 0; pattern = pattern << 1)
      begin
        // Write the test pattern. *address = pattern;pio_memTestAddrBus_test1

        TSK_TX_BAR_WRITE(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC, pattern);
        TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);


        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Data Error Mismatch, Address: %x Write Data %x != Read Data %x", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], pattern, P_READ_DATA);
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Address: %x Write Data: %x successfully received", $realtime,
                              BAR_INIT_P_BAR[bar_index][31:0], P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end  // for loop
    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DATA_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DATA_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DATA_BUS



/************************************************************
        Task : TSK_MEM_TEST_ADDR_BUS
        Inputs : bar_index, nBytes
        Outputs : None
        Description : Test the address bus wiring in a specific memory by
               performing a walking 1's test on the relevant bits
               of the address and checking for multiple writes/aliasing.
               This test will find single-bit address failures such as stuck
               -high, stuck-low, and shorted pins.

*************************************************************/

task TSK_MEM_TEST_ADDR_BUS;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] addressMask;
   reg [31:0] offset;
   reg [31:0] testOffset;
   reg success;
   reg stuckHi_success;
   reg stuckLo_success;
   begin

    $display("[%t] : Performing Memory address test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success
    stuckHi_success = 1;
    stuckLo_success = 1;

    pattern =     32'hAAAAAAAA;
    antipattern = 32'h55555555;

    // divide by 4 because the block RAMS we are testing are 32bit wide
    // and therefore the low two bits are not meaningful for addressing purposes
    // for this test.
    addressMask = (nBytes/4 - 1);

    $display("[%t] : Checking for address bits stuck high", $realtime);
    // Write the default pattern at each of the power-of-two offsets.
    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin

        verbose = 1;

        // baseAddress[offset] = pattern
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;
      end



    // Check for address bits stuck high.
    // It should be noted that since the write address and read address pins are different
    // for the block RAMs used in the PIO design, the stuck high test will only catch an error if both
    // read and write addresses are both stuck hi. Otherwise the remaining portion of the tests
    // will catch if only one of the addresses are stuck hi.

    testOffset = 0;

    // baseAddress[testOffset] = antipattern;
    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;


    for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
      begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)
           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                     $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
             stuckHi_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

     end


    if (stuckHi_success == 1)
        $display("[%t] : Stuck Hi Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Hi Address Test failed", $realtime);


    $display("[%t] : Checking for address bits stuck low or shorted", $realtime);

    //baseAddress[testOffset] = pattern;

    TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


    TSK_TX_CLK_EAT(10);
    DEFAULT_TAG = DEFAULT_TAG + 1;

    // Check for address bits stuck low or shorted.
    for (testOffset = 1; (testOffset & addressMask) != 0; testOffset = testOffset << 1)
      begin

        //baseAddress[testOffset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

        TSK_TX_BAR_READ(bar_index, 32'h0, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        if  (P_READ_DATA != pattern)      // if (baseAddress[0] != pattern)

           begin
             $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*0), pattern, P_READ_DATA);
             stuckLo_success = 0;
             success = 0;
             $finish;
           end
        else
           begin
             $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                      $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), P_READ_DATA);
           end
        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


        for (offset = 1; (offset & addressMask) != 0; offset = offset << 1)
           begin

             TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

             TSK_WAIT_FOR_READ_DATA;
             // if ((baseAddress[offset] != pattern) && (offset != testOffset))
             if  ((P_READ_DATA != pattern) && (offset != testOffset))
                begin
                  $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x",
                                                 $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                                 pattern, P_READ_DATA);
                  stuckLo_success = 0;
                  success = 0;
                  $finish;
                end
             else
                begin
                  $display("[%t] : Pattern Match: Address %x Data: %x successfully received",
                                              $realtime, BAR_INIT_P_BAR[bar_index][31:0]+(4*offset),
                                              P_READ_DATA);
                end
             TSK_TX_CLK_EAT(10);
             DEFAULT_TAG = DEFAULT_TAG + 1;

          end

        // baseAddress[testOffset] = pattern;


        TSK_TX_BAR_WRITE(bar_index, 4*testOffset, DEFAULT_TAG, DEFAULT_TC, pattern);


        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;

      end

    if (stuckLo_success == 1)
        $display("[%t] : Stuck Low Address Test successfully completed", $realtime);
    else
        $display("[%t] : Error: Stuck Low Address Test failed", $realtime);


    if (success == 1)
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_ADDR_BUS completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_ADDR_BUS



/************************************************************
        Task : TSK_MEM_TEST_DEVICE
        Inputs : bar_index, nBytes
        Outputs : None
 *      Description: Test the integrity of a physical memory device by
 *              performing an increment/decrement test over the
 *              entire region.  In the process every storage bit
 *              in the device is tested as a zero and a one.  The
 *              bar_index and the size of the region are
 *              selected by the caller.
*************************************************************/

task TSK_MEM_TEST_DEVICE;
   input [2:0] bar_index;
   input [31:0] nBytes;
   reg [31:0] pattern;
   reg [31:0] antipattern;
   reg [31:0] offset;
   reg [31:0] nWords;
   reg success;
   begin

    $display("[%t] : Performing Memory device test to address %x", $realtime, BAR_INIT_P_BAR[bar_index][31:0]);
    success = 1; // assume success

    nWords = nBytes / 4;

    pattern = 1;
    // Fill memory with a known pattern.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin

        verbose = 1;

        //baseAddress[offset] = pattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, pattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        pattern = pattern + 1;
    end


   pattern = 1;
    // Check each location and invert it for the second pass.
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin


        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != pattern)
        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end


        antipattern = ~pattern;

        //baseAddress[offset] = antipattern;
        TSK_TX_BAR_WRITE(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC, antipattern);

        TSK_TX_CLK_EAT(10);
        DEFAULT_TAG = DEFAULT_TAG + 1;


       pattern = pattern + 1;
    end

    pattern = 1;
    // Check each location for the inverted pattern
    for (offset = 0; offset < nWords; offset = offset + 1)
    begin
        antipattern = ~pattern;

        TSK_TX_BAR_READ(bar_index, 4*offset, DEFAULT_TAG, DEFAULT_TC);

        TSK_WAIT_FOR_READ_DATA;
        DEFAULT_TAG = DEFAULT_TAG + 1;
        //if (baseAddress[offset] != pattern)
        if  (P_READ_DATA != antipattern)

        begin
           $display("[%t] : Error: Pattern Mismatch, Address = %x, Write Data %x != Read Data %x", $realtime,
                            BAR_INIT_P_BAR[bar_index][31:0]+(4*offset), pattern, P_READ_DATA);
           success = 0;
           $finish;
        end
        pattern = pattern + 1;
    end

     if (success == 1)
        $display("[%t] : TSK_MEM_TEST_DEVICE successfully completed", $realtime);
    else
        $display("[%t] : TSK_MEM_TEST_DEVICE completed with errors", $realtime);

   end

endtask   // TSK_MEM_TEST_DEVICE


/************************************************************
Function : FNC_CONVERT_RANGE_TO_SIZE_32
Inputs : BAR index for 32 bit BAR
Outputs : 32 bit BAR size
Description : Called from tx app. Note that the smallest range
              supported by this function is 16 bytes.
*************************************************************/

function [31:0] FNC_CONVERT_RANGE_TO_SIZE_32;
            input [31:0] bar_index;
            reg   [32:0] return_value;
    begin
              case (BAR_INIT_P_BAR_RANGE[bar_index] & 32'hFFFF_FFF0) // AND off control bits
                32'hFFFF_FFF0 : return_value = 33'h0000_0010;
                32'hFFFF_FFE0 : return_value = 33'h0000_0020;
                32'hFFFF_FFC0 : return_value = 33'h0000_0040;
                32'hFFFF_FF80 : return_value = 33'h0000_0080;
                32'hFFFF_FF00 : return_value = 33'h0000_0100;
                32'hFFFF_FE00 : return_value = 33'h0000_0200;
                32'hFFFF_FC00 : return_value = 33'h0000_0400;
                32'hFFFF_F800 : return_value = 33'h0000_0800;
                32'hFFFF_F000 : return_value = 33'h0000_1000;
                32'hFFFF_E000 : return_value = 33'h0000_2000;
                32'hFFFF_C000 : return_value = 33'h0000_4000;
                32'hFFFF_8000 : return_value = 33'h0000_8000;
                32'hFFFF_0000 : return_value = 33'h0001_0000;
                32'hFFFE_0000 : return_value = 33'h0002_0000;
                32'hFFFC_0000 : return_value = 33'h0004_0000;
                32'hFFF8_0000 : return_value = 33'h0008_0000;
                32'hFFF0_0000 : return_value = 33'h0010_0000;
                32'hFFE0_0000 : return_value = 33'h0020_0000;
                32'hFFC0_0000 : return_value = 33'h0040_0000;
                32'hFF80_0000 : return_value = 33'h0080_0000;
                32'hFF00_0000 : return_value = 33'h0100_0000;
                32'hFE00_0000 : return_value = 33'h0200_0000;
                32'hFC00_0000 : return_value = 33'h0400_0000;
                32'hF800_0000 : return_value = 33'h0800_0000;
                32'hF000_0000 : return_value = 33'h1000_0000;
                32'hE000_0000 : return_value = 33'h2000_0000;
                32'hC000_0000 : return_value = 33'h4000_0000;
                32'h8000_0000 : return_value = 33'h8000_0000;
                default :      return_value = 33'h0000_0000;
              endcase

              FNC_CONVERT_RANGE_TO_SIZE_32 = return_value;
    end
endfunction // FNC_CONVERT_RANGE_TO_SIZE_32



/************************************************************
Function : FNC_CONVERT_RANGE_TO_SIZE_HI32
Inputs : BAR index for upper 32 bit BAR of 64 bit address
Outputs : upper 32 bit BAR size
Description : Called from tx app.
*************************************************************/

function [31:0] FNC_CONVERT_RANGE_TO_SIZE_HI32;
            input [31:0] bar_index;
            reg   [32:0] return_value;
    begin
              case (BAR_INIT_P_BAR_RANGE[bar_index])
                32'hFFFF_FFFF : return_value = 33'h00000_0001;
                32'hFFFF_FFFE : return_value = 33'h00000_0002;
                32'hFFFF_FFFC : return_value = 33'h00000_0004;
                32'hFFFF_FFF8 : return_value = 33'h00000_0008;
                32'hFFFF_FFF0 : return_value = 33'h00000_0010;
                32'hFFFF_FFE0 : return_value = 33'h00000_0020;
                32'hFFFF_FFC0 : return_value = 33'h00000_0040;
                32'hFFFF_FF80 : return_value = 33'h00000_0080;
                32'hFFFF_FF00 : return_value = 33'h00000_0100;
                32'hFFFF_FE00 : return_value = 33'h00000_0200;
                32'hFFFF_FC00 : return_value = 33'h00000_0400;
                32'hFFFF_F800 : return_value = 33'h00000_0800;
                32'hFFFF_F000 : return_value = 33'h00000_1000;
                32'hFFFF_E000 : return_value = 33'h00000_2000;
                32'hFFFF_C000 : return_value = 33'h00000_4000;
                32'hFFFF_8000 : return_value = 33'h00000_8000;
                32'hFFFF_0000 : return_value = 33'h00001_0000;
                32'hFFFE_0000 : return_value = 33'h00002_0000;
                32'hFFFC_0000 : return_value = 33'h00004_0000;
                32'hFFF8_0000 : return_value = 33'h00008_0000;
                32'hFFF0_0000 : return_value = 33'h00010_0000;
                32'hFFE0_0000 : return_value = 33'h00020_0000;
                32'hFFC0_0000 : return_value = 33'h00040_0000;
                32'hFF80_0000 : return_value = 33'h00080_0000;
                32'hFF00_0000 : return_value = 33'h00100_0000;
                32'hFE00_0000 : return_value = 33'h00200_0000;
                32'hFC00_0000 : return_value = 33'h00400_0000;
                32'hF800_0000 : return_value = 33'h00800_0000;
                32'hF000_0000 : return_value = 33'h01000_0000;
                32'hE000_0000 : return_value = 33'h02000_0000;
                32'hC000_0000 : return_value = 33'h04000_0000;
                32'h8000_0000 : return_value = 33'h08000_0000;
                default :      return_value = 33'h00000_0000;
              endcase

              FNC_CONVERT_RANGE_TO_SIZE_HI32 = return_value;
    end
endfunction // FNC_CONVERT_RANGE_TO_SIZE_HI32

/***********************************************************************************
 *
 *   DMA DESIGN TASKS
 *
 ***********************************************************************************/


/************************************************************
    Task : DMA_BAR_SCAN
    Inputs : None
    Outputs : None
    Description : Assigns PCI core's configuration registers. The values
                  are already known for PCIE core.

#  BAR 0: VALUE = 00000000 RANGE = fffffc04 TYPE = MEM64 MAPPED
#  BAR 1: VALUE = 00000001 RANGE = ffffffff TYPE = DISABLED
#  BAR 2: VALUE = 00000000 RANGE = 00000000 TYPE = DISABLED
#  BAR 3: VALUE = 00000000 RANGE = 00000000 TYPE = DISABLED
#  BAR 4: VALUE = 00000000 RANGE = 00000000 TYPE = DISABLED
#  BAR 5: VALUE = 00000000 RANGE = 00000000 TYPE = DISABLED
#  EROM : VALUE = 00000001 RANGE = fff00001 TYPE = MEM32 MAPPED

*************************************************************/

task DMA_BAR_SCAN;
    begin
        $display("[%t] : Assigning Core Configuration Space...", $realtime);
        BAR_INIT_P_BAR_RANGE[0] = 32'hfffffc04;
        BAR_INIT_P_BAR_RANGE[1] = 32'hffffffff;
        BAR_INIT_P_BAR_RANGE[2] = 32'h00000000;
        BAR_INIT_P_BAR_RANGE[3] = 32'h00000000;
        BAR_INIT_P_BAR_RANGE[4] = 32'h00000000;
        BAR_INIT_P_BAR_RANGE[5] = 32'h00000000;
        BAR_INIT_P_BAR_RANGE[6] = 32'hfff00001;
    end
endtask // DMA_BAR_SCAN


/************************************************************
Task : DMA_BUILD_PCIE_MAP
Inputs :
Outputs :
Description : Looks at range values read from config space and
              builds corresponding mem/io map
*************************************************************/

task DMA_BUILD_PCIE_MAP;
    integer ii;

    begin
        $display("[%t] PCI EXPRESS BAR MEMORY/IO MAPPING PROCESS BEGUN...",$realtime);

        BAR_INIT_P_BAR_ENABLED[0] = 2'h3;   // BAR0 is MEM64 MAPPED
        BAR_INIT_P_BAR_ENABLED[1] = 2'h0;   // DISABLED
        BAR_INIT_P_BAR_ENABLED[2] = 2'h0;   // DISABLED
        BAR_INIT_P_BAR_ENABLED[3] = 2'h0;   // DISABLED
        BAR_INIT_P_BAR_ENABLED[4] = 2'h0;   // DISABLED
        BAR_INIT_P_BAR_ENABLED[5] = 2'h0;   // DISABLED
        BAR_INIT_P_BAR_ENABLED[6] = 2'h2;   // EROM is MEM32 MAPPED

        BAR_INIT_P_BAR[0] = 33'b0;
        BAR_INIT_P_BAR[1] = 33'b1;
        BAR_INIT_P_BAR[2] = 33'b0;
        BAR_INIT_P_BAR[3] = 33'b0;
        BAR_INIT_P_BAR[4] = 33'b0;
        BAR_INIT_P_BAR[5] = 33'b0;
        BAR_INIT_P_BAR[6] = 33'b1;
    end
endtask // DMA_BUILD_PCIE_MAP

/************************************************************
    Task : DMA_BAR_INIT
    Inputs : None
    Outputs : None
    Description : Initialize PCI core based on core's configuration.
*************************************************************/

task DMA_BAR_INIT;
   begin
//       DMA_BAR_SCAN;
//       DMA_BUILD_PCIE_MAP;
       TSK_BAR_SCAN;
       TSK_BUILD_PCIE_MAP;
       TSK_DISPLAY_PCIE_MAP;
       TSK_BAR_PROGRAM;
   end
endtask // DMA_BAR_INIT

/************************************************************
    Task : DMA_DISP_CSR
    Inputs : Control and Status Register address
    Outputs : None
    Description : Reads and display CSR
*************************************************************/
task DMA_DISP_CSR;
    input   [12:0]  addr;

    begin
        P_READ_DATA = 32'hffff_ffff;
        TSK_TX_MEMORY_READ_32(DEFAULT_TAG, DEFAULT_TC, 10'd1, BAR_INIT_P_BAR[0][31:0] + addr, 4'h0, 4'hF);
        TSK_WAIT_FOR_READ_DATA;
        $display("[%t] : %s value = %x", $realtime, DMA_CSR_NAME[addr[12:2]], P_READ_DATA);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(10);
    end
endtask //DMA_DISP_CSR

/************************************************************
    Task : DMA_SET_CSR
    Inputs : Writes to CSRs
    Outputs : None
    Description : Writes to CSR
*************************************************************/
task DMA_SET_CSR;
    input   [12:0]  addr;
    input   [31:0]  val;

    begin
        DATA_STORE[0] = val[7 : 0];
        DATA_STORE[1] = val[15: 8];
        DATA_STORE[2] = val[23:16];
        DATA_STORE[3] = val[31:24];

        TSK_TX_CLK_EAT(100);
        $display("[%t] : Writing %x to %s", $realtime, val, DMA_CSR_NAME[addr[12:2]]);
        TSK_TX_MEMORY_WRITE_32(DEFAULT_TAG, DEFAULT_TC, 10'd1, BAR_INIT_P_BAR[0][31:0] + addr, 4'h0, 4'hF, 1'b0);
        DEFAULT_TAG = DEFAULT_TAG + 1;
    end
endtask //DMA_DISP_CSR


/************************************************************
    Task : DMA_WRITE_DEVICE_PREPARE
    Inputs : Writes to CSRs
    Outputs : None
    Description : Writes to CSR
*************************************************************/
task DMA_WRITE_DEVICE_PREPARE;
    input [12: 0]   wSize;
    input [15: 0]   wCount;
    input [31: 0]   u32Pattern;
    input           fEnable64bit;
    input [ 2: 0]   bTrafficClass;
    input [31: 0]   LowerAddr;
    input [ 7: 0]   UpperAddr;

    reg   [31: 0]   tlps;

    begin
        tlps[12:0]  = wSize;
        tlps[15:13] = 3'b0; // reserved
        tlps[18:16] = bTrafficClass;
        tlps[19]    = fEnable64bit;
        tlps[23:20] = 4'b0; // reserved
        tlps[31:24] = UpperAddr;

        DMA_SET_CSR(PCIE_WDMATLPA, LowerAddr);  // Write DMA H/W Address
        DMA_SET_CSR(PCIE_WDMATLPS, tlps);       // Write DMA TLP Size, Traffic Class, Upper 8-bit DMA Addr
        DMA_SET_CSR(PCIE_WDMATLPC, wCount);     // Write DMA TLP Count
        DMA_SET_CSR(PCIE_WDMATLPP, u32Pattern); // TLP Payload Pattern
    end
endtask //DMA_WRITE_DEVICE_PREPARE


/************************************************************
    Task : DMA_READ_DEVICE_PREPARE
    Inputs : Writes to CSRs
    Outputs : None
    Description : Writes to CSR
*************************************************************/
task DMA_READ_DEVICE_PREPARE;
    input [12: 0]   wSize;
    input [15: 0]   wCount;
    input [31: 0]   u32Pattern;
    input           fEnable64bit;
    input [ 2: 0]   bTrafficClass;
    input [31: 0]   LowerAddr;
    input [ 7: 0]   UpperAddr;

    reg   [31: 0]   tlps;

    begin
        tlps[12:0]  = wSize;
        tlps[15:13] = 3'b0; // reserved
        tlps[18:16] = bTrafficClass;
        tlps[19]    = fEnable64bit;
        tlps[23:20] = 4'b0; // reserved
        tlps[31:24] = UpperAddr;

        DMA_SET_CSR(PCIE_RDMATLPA, LowerAddr);  // Write DMA H/W Address
        DMA_SET_CSR(PCIE_RDMATLPS, tlps);       // Write DMA TLP Size, Traffic Class, Upper 8-bit DMA Addr
        DMA_SET_CSR(PCIE_RDMATLPC, wCount);     // Write DMA TLP Count
        DMA_SET_CSR(PCIE_RDMATLPP, u32Pattern); // TLP Payload Pattern

    end
endtask //DMA_READ_DEVICE_PREPARE

/************************************************************
    Task : DMA_READ_DEVICE_PREPARE
    Inputs : Writes to CSRs
    Outputs : None
    Description : Writes to CSR
*************************************************************/
task DMA_DEVICE_INIT;
    input       dma_scgt_en;

    begin

        if (dma_scgt_en) begin
            // Assert initiator Reset
            DMA_SET_CSR(PCIE_DCSR, 32'h80000001);
            // De-assert initiator Reset
            DMA_SET_CSR(PCIE_DCSR, 32'h80000000);
        end
        else begin
            // Assert initiator Reset
            DMA_SET_CSR(PCIE_DCSR, 32'h00000001);
            // De-assert initiator Reset
            DMA_SET_CSR(PCIE_DCSR, 32'h00000000);
        end

    end
endtask


/************************************************************
    Task : CONFIGURE_CC
    Inputs : 
    Outputs : None
    Description : Configures CC via FAI
*************************************************************/
task CONFIGURE_CC;
    input [31:0]    bpmid;
    input [31:0]    timeframe_length;

    begin
        DMA_SET_CSR(4096, bpmid);
        DMA_SET_CSR(4100, timeframe_length);
        DMA_SET_CSR(FAI_CFGVAL, 32'h9);
        DMA_SET_CSR(FAI_CFGVAL, 32'h8);
    end

endtask //CONFIGURE_CC

/************************************************************
    Task : MONITOR_CC
    Inputs : None
    Outputs : None
    Description : Read status information from CC
*************************************************************/
task MONITOR_CC;

    reg [31: 0]     regaddr;

    begin

        regaddr = 4096;

        for (regaddr = 4096; regaddr <= 4096 + (16 * 4); regaddr = regaddr + 4) begin

            TSK_TX_CLK_EAT(100);
            P_READ_DATA = 32'hffff_ffff;
            TSK_TX_MEMORY_READ_32(DEFAULT_TAG, DEFAULT_TC, 10'd1, BAR_INIT_P_BAR[0][31:0]+regaddr, 4'h0, 4'hF);
            TSK_WAIT_FOR_READ_DATA;
            $display("[%t] : Data at %x is %x ", $realtime, regaddr, P_READ_DATA);
            DEFAULT_TAG = DEFAULT_TAG + 1;

        end

    end

endtask //MONITOR_CC

endmodule // pci_exp_usrapp_tx

