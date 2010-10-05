else if(testname == "fulltest")
begin
    TSK_SIMULATION_TIMEOUT(500000);
    TSK_SYSTEM_INITIALIZATION;

    DMA_BAR_INIT;

    DMA_SET_CSR(4096, 32'h000000C8);
    DMA_SET_CSR(4100, 32'h00001D4C);
    DMA_SET_CSR(FAI_CFGVAL, 32'h9);
    DMA_SET_CSR(FAI_CFGVAL, 32'h8);

    /*
     * Configure Write DMA transfer
     */
    wSize         = 13'h20;     // 32 x 4 bytes = 128 bytes per TLP
    wCount        = 16'h10;     // 16 TLPs
    u32Pattern    = 32'h2;
    fEnable64bit  = 1'b1;
    bTrafficClass = 3'b0;
    LowerAddr     = 32'h081049C8;
    UpperAddr     = 8'b0;

    RDMA64_START_ADDR = {{24'b0}, UpperAddr, LowerAddr};
    RDMA64_TLP_SIZE = 10'h5;

    DMA_DEVICE_INIT(1'b1);

    DMA_WRITE_DEVICE_PREPARE(wSize, wCount, u32Pattern, fEnable64bit, bTrafficClass, LowerAddr, UpperAddr);

    DMA_READ_DEVICE_PREPARE(13'h5, 16'h1, 0, fEnable64bit, 0, LowerAddr, UpperAddr);

    // Start Sniffer Data Capture
    DMA_SET_CSR(PCIE_DDMACR, 32'h00000001);

    board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_EXPECT_MEMRD64(
        DEFAULT_TC,     // Traffic Class
        1'b0,
        1'b0,
        2'h0,
        RDMA64_TLP_SIZE,
        16'h01A0,
        8'h1,
        4'hF,
        4'hF,
        RDMA64_START_ADDR[63:2],
        expect_status
    );

    // Set Lower and Upper DMA Write addresses to 0
    for (i=0; i < RDMA64_TLP_SIZE * 4; i = i+1) begin
        DATA_STORE[i] = 0;
    end
    // Set number of frames to 1
    DATA_STORE[3] = 3;

    // Set pointer to non-zero address
    //DATA_STORE[16] = 8'h10;

    TSK_TX_COMPLETION_DATA (
        DEFAULT_TAG,        // tag
        DEFAULT_TC,         // TC
        RDMA64_TLP_SIZE,    // Length
        10'h0,              // Byte Count
        7'b0,               // Lower Address
        3'b0,               // Completion Status
        1'b0                // EP
    );

    //Expect Interrupt coming
    //Expect MSI coming
    board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_EXPECT_MSI(
        DEFAULT_TC,     //Traffic Class 
        1'b0,           //TD 
        1'b0,           //EP 
        2'h0,           //Attributes 
        10'h1,          //Length 
        16'h01a0,       //Requester Id 
        8'h0,           //Tag
        4'h0,
        4'h0,
        30'h0,          //[29:0] address
        expect_status);
//    board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_EXPECT_INTR(
//        DEFAULT_TC,     //Traffic Class 
//        1'b0,           //TD 
//        1'b0,           //EP 
//        2'h0,           //Attributes 
//        10'h0,          //Length 
//        16'h01a0,       //Requester Id 
//        8'h0,           //Tag 
//        3'h4,           //Message Type 
//        8'h20,          //Message Code 
//        expect_status);

TSK_TX_CLK_EAT(5000);

$finish;

end
