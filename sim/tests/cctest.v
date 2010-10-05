else if(testname == "cctest")
begin
    TSK_SIMULATION_TIMEOUT(250000);
    TSK_SYSTEM_INITIALIZATION;

    DMA_BAR_INIT;

    TSK_TX_CLK_EAT(500);

    CONFIGURE_CC(200,7500);

//    MONITOR_CC();

    TSK_TX_CLK_EAT(50000);

    $finish;

end
