else if(testname == "wdmatest")
begin
    TSK_SIMULATION_TIMEOUT(500000);
    TSK_SYSTEM_INITIALIZATION;

    DMA_BAR_INIT;

//    DMA_SET_CSR(4096, 32'h000000C8);
//    DMA_SET_CSR(4100, 32'h00001D4C);
//    DMA_SET_CSR(FAI_CFGVAL, 32'h9);
    TSK_TX_CLK_EAT(1000);
    DMA_SET_CSR(FAI_CFGVAL, 32'h8);

    /*
     * Configure Write DMA transfer
     */
    wSize         = 13'h20;     // 32 x 4 bytes = 128 bytes per TLP
    wCount        = 16'h10;     // 16 TLPs
    u32Pattern    = 32'h00000002;
    fEnable64bit  = 1'b1;
    bTrafficClass = 3'b0;
    LowerAddr     = 32'h081049C8;
    UpperAddr     = 8'b0;

    DMA_DEVICE_INIT(1'b1);
    DMA_WRITE_DEVICE_PREPARE(wSize, wCount, u32Pattern, fEnable64bit, bTrafficClass, LowerAddr, UpperAddr);

    // Start Sniffer Data Capture
    DMA_SET_CSR(PCIE_DDMACR, 32'h00000001);

    TSK_TX_CLK_EAT(1000);
    DMA_WRITE_DEVICE_PREPARE(wSize, wCount, u32Pattern, fEnable64bit, bTrafficClass, LowerAddr, UpperAddr);

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

    // Stop Sniffer Data Capture
    TSK_TX_CLK_EAT(100);
    DMA_SET_CSR(PCIE_DDMACR, 32'h00000002);

    TSK_TX_CLK_EAT(100000);

$finish;

end
