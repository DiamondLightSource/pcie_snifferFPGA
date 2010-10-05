
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
// FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
// IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
// MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
// and (2) Xilinx shall not be liable (whether in contract or tort, including
// negligence, or under any other theory of liability) for any loss or damage
// of any kind or nature related to, arising under or in connection with these
// materials, including for any direct, or any indirect, special, incidental,
// or consequential loss or damage (including loss of data, profits, goodwill,
// or any type of loss or damage suffered as a result of any action brought by
// a third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// CRITICAL APPLICATIONS
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other
// applications that could lead to death, personal injury, or severe property
// or environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : V5-Block Plus for PCI Express
// File       : pcie_blk_cf_int.v
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--
//-- Description: PCIe Block LocalLink Bridge, Interrupt Module
//--
//--             
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns
`ifndef TCQ
 `define TCQ 1
`endif

module pcie_blk_cf_int
(
       // Clock and reset

       input wire         clk,
       input wire         rst_n,

       // Arb interface
       output reg         send_intr32,
       output reg         send_intr64,
       input  wire        cs_is_intr,
       input  wire        grant,
       input  wire [31:0] cfg_msguaddr,

       // PCIe Block Interrupt Ports
       
       input  wire        msi_enable,
       output reg  [3:0]  msi_request,
       output reg         legacy_int_request,

       // LocalLink Interrupt Ports

       input  wire        cfg_interrupt_n,
       output reg         cfg_interrupt_rdy_n
); 

reg       msi64_enabled;
reg       msi_enable_reg;

always @(posedge clk) 
begin
  msi_enable_reg <= msi_enable;
end

always @(posedge clk)
begin
  if (~rst_n) begin
    msi_request         <= #`TCQ 'b0000;
    legacy_int_request  <= #`TCQ 0;
    send_intr32         <= #`TCQ 0;
    send_intr64         <= #`TCQ 0;
    cfg_interrupt_rdy_n <= #`TCQ 1;
  end else begin
    if (msi_enable_reg) begin 
      msi_request         <= #`TCQ {3'b000, 1'b0}; //disabled due to block malfunction
      legacy_int_request  <= #`TCQ 0;
      if(~cfg_interrupt_n) begin
        send_intr32         <= #`TCQ ~msi64_enabled;
        send_intr64         <= #`TCQ  msi64_enabled;
        cfg_interrupt_rdy_n <= #`TCQ 1;
      end else if (cfg_interrupt_rdy_n && (cs_is_intr && grant)) begin
        send_intr32         <= #`TCQ 0;
        send_intr64         <= #`TCQ 0;
        cfg_interrupt_rdy_n <= #`TCQ 0;
      end
    end
    else if (~msi_enable_reg) begin 
      msi_request         <= #`TCQ 'b0000;
      legacy_int_request  <= #`TCQ ~cfg_interrupt_n;
      send_intr32         <= #`TCQ 0;
      send_intr64         <= #`TCQ 0;
      cfg_interrupt_rdy_n <= #`TCQ 0;
    end
  end
end

// If upper address is 0, then send MSI32, otherwise send MSI64
always @(posedge clk)
begin
  if (~rst_n) begin
    msi64_enabled       <= #`TCQ 0;
  end else begin
    msi64_enabled       <= #`TCQ (cfg_msguaddr != 0);
  end
end

endmodule // pcie_blk_cf_int

