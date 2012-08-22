`timescale 1ns / 1ns

module bmd_intr_ctrl_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg init_rst_i;
    reg mrd_done_i;
    reg mwr_done_i;
    reg msi_on;
    reg cfg_interrupt_rdy_n_i;
    reg cfg_interrupt_legacyclr;

    // Outputs
    wire cfg_interrupt_assert_n_o;
    wire cfg_interrupt_n_o;

// Instantiate the Unit Under Test (UUT)
BMD_INTR_CTRL uut (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .init_rst_i                 (init_rst_i                 ),
    .mrd_done_i                 (mrd_done_i                 ),
    .mwr_done_i                 (mwr_done_i                 ),
    .msi_on                     (msi_on                     ),
    .cfg_interrupt_assert_n_o   (cfg_interrupt_assert_n_o   ),
    .cfg_interrupt_rdy_n_i      (cfg_interrupt_rdy_n_i      ),
    .cfg_interrupt_n_o          (cfg_interrupt_n_o          ),
    .cfg_interrupt_legacyclr    (cfg_interrupt_legacyclr    )
);

initial begin
    clk = 0;
    forever #(4) clk = ~clk;
end

initial begin
    rst_n = 0;
    repeat(100) @(posedge clk);
    rst_n = 1;
end


initial begin
    mrd_done_i = 0;
    cfg_interrupt_legacyclr = 0;

end

initial begin
    // Initialize Inputs
    init_rst_i = 0;
    mwr_done_i = 0;
    msi_on = 1;
    cfg_interrupt_rdy_n_i = 1;

    // Wait for global reset to finish
    repeat(150) @(posedge clk);
    init_rst_i = 1;
    @(posedge clk);
    init_rst_i = 0;
    @(posedge clk);
    mwr_done_i = 1;
    @(posedge clk);
    mwr_done_i = 0;
    repeat(100)@(posedge clk);
    cfg_interrupt_rdy_n_i = 0;
    @(posedge clk);
    cfg_interrupt_rdy_n_i = 1;


    repeat(250) @(posedge clk);
    init_rst_i = 1;
    @(posedge clk);
    init_rst_i = 0;
    @(posedge clk);
    mwr_done_i = 1;
    @(posedge clk);
    mwr_done_i = 0;
    repeat(100)@(posedge clk);
    cfg_interrupt_rdy_n_i = 0;
    @(posedge clk);
    cfg_interrupt_rdy_n_i = 1;

end

endmodule
