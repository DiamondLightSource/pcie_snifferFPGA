else if(testname == "rdmatest")
begin
    TSK_SIMULATION_TIMEOUT(500000);
    TSK_SYSTEM_INITIALIZATION;

    DMA_BAR_INIT;

    /*
     * Configure DMA Read
     */
    wSize         = 13'h5;
    wCount        = 16'h1;
    u32Pattern    = 32'h1;
    fEnable64bit  = 1'b1;
    bTrafficClass = 3'b0;
    LowerAddr     = 32'h11223344;
    UpperAddr     = 8'b0;

    RDMA64_START_ADDR = {{24'b0}, UpperAddr, LowerAddr};
    RDMA64_TLP_SIZE = wSize[9:0];

    DMA_READ_DEVICE_PREPARE(wSize, wCount, u32Pattern, fEnable64bit, bTrafficClass, LowerAddr, UpperAddr);
    // Read DMA Start
    DMA_SET_CSR(PCIE_DDMACR, 32'h00010000);

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


    for (i=0; i < RDMA64_TLP_SIZE * 4; i = i+1) begin
        DATA_STORE[i] = i;
    end

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
    board.xilinx_pci_exp_4_lane_downstream_port.com_usrapp.TSK_EXPECT_INTR(
        DEFAULT_TC,     //Traffic Class 
        1'b0,           //TD 
        1'b0,           //EP 
        2'h0,           //Attributes 
        10'h0,          //Length 
        16'h01a0,       //Requester Id 
        8'h0,           //Tag 
        3'h4,           //Message Type 
        8'h20,          //Message Code 
        expect_status);


    TSK_TX_CLK_EAT(50);

    $finish;

end
















