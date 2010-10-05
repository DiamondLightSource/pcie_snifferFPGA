//
// ICON core module declaration
//
module icon (
    control0
);

output [35:0] control0;

endmodule

//
// ILA core module declaration
//
module ila (
    control,
    clk,
    data,
    trig0
);

    input [35:0]  control;
    input         clk;
    input [255:0] data;
    input [7:0]   trig0;

endmodule


