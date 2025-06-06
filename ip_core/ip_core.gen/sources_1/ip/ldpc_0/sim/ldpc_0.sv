// (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:ldpc:2.0
// IP Revision: 11

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module ldpc_0 (
  reset_n,
  core_clk,
  s_axi_awaddr,
  s_axi_awvalid,
  s_axi_awready,
  s_axi_wdata,
  s_axi_wvalid,
  s_axi_wready,
  s_axi_bready,
  s_axi_bvalid,
  s_axi_araddr,
  s_axi_arvalid,
  s_axi_arready,
  s_axi_rready,
  s_axi_rdata,
  s_axi_rvalid,
  interrupt,
  s_axis_ctrl_tready,
  s_axis_ctrl_tvalid,
  s_axis_ctrl_tdata,
  s_axis_din_tready,
  s_axis_din_tvalid,
  s_axis_din_tlast,
  s_axis_din_tdata,
  m_axis_status_tready,
  m_axis_status_tvalid,
  m_axis_status_tdata,
  m_axis_dout_tready,
  m_axis_dout_tvalid,
  m_axis_dout_tlast,
  m_axis_dout_tdata
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME reset_n_intf, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 reset_n_intf RST" *)
input wire reset_n;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clock_intf, ASSOCIATED_BUSIF S_AXIS_CTRL:S_AXIS_DIN:S_AXIS_DIN_WORDS:S_AXIS_DOUT_WORDS:M_AXIS_DOUT:M_AXIS_STATUS:S_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clock_intf CLK" *)
input wire core_clk;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
input wire [17 : 0] s_axi_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
input wire s_axi_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
output wire s_axi_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
input wire [31 : 0] s_axi_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
input wire s_axi_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
output wire s_axi_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
input wire s_axi_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
output wire s_axi_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
input wire [17 : 0] s_axi_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
input wire s_axi_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
output wire s_axi_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
input wire s_axi_rready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
output wire [31 : 0] s_axi_rdata;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 100000000, ID_WIDTH 0, ADDR_WIDTH 18, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 0, HAS_BRESP 0, HAS_RRESP 0, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_B\
ITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
output wire s_axi_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME interrupt_intf, SENSITIVITY EDGE_RISING, PortWidth 1" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt_intf INTERRUPT" *)
output wire interrupt;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTRL TREADY" *)
output wire s_axis_ctrl_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTRL TVALID" *)
input wire s_axis_ctrl_tvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS_CTRL, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTRL TDATA" *)
input wire [31 : 0] s_axis_ctrl_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DIN TREADY" *)
output wire s_axis_din_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DIN TVALID" *)
input wire s_axis_din_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DIN TLAST" *)
input wire s_axis_din_tlast;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS_DIN, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DIN TDATA" *)
input wire [127 : 0] s_axis_din_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_STATUS TREADY" *)
input wire m_axis_status_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_STATUS TVALID" *)
output wire m_axis_status_tvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS_STATUS, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_STATUS TDATA" *)
output wire [31 : 0] m_axis_status_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TREADY" *)
input wire m_axis_dout_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TVALID" *)
output wire m_axis_dout_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TLAST" *)
output wire m_axis_dout_tlast;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS_DOUT, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TDATA" *)
output wire [127 : 0] m_axis_dout_tdata;

  ldpc_v2_0_11 #(
    .C_XDEVICEFAMILY("virtex7"),
    .ENCODE(0),
    .ONLY_5G(0),
    .OUTPUT_PARITY_CHECK(1),
    .PACKING(1),
    .ALGORITHM(0),
    .VERSION_REGISTER(33557248),
    .C_ELABORATION_DIR("./"),
    .CORE_AXI_WR_PROTECT(32'H00000000),
    .CORE_CODE_WR_PROTECT(32'H00000000),
    .CORE_AXIS_WIDTH(32'H00000000),
    .CORE_AXIS_ENABLE(32'H00000000),
    .CORE_ORDER(32'H00000000),
    .CORE_IMR(32'H0000007F),
    .CORE_ECC_IMR(32'H003FFFFF),
    .CORE_BYPASS(32'H00000000),
    .QC_TABLE0_FILENAME("NO_INIT"),
    .QC_TABLE1_FILENAME("NO_INIT"),
    .QC_TABLE2_FILENAME("NO_INIT"),
    .QC_TABLE3_FILENAME("NO_INIT"),
    .QC_TABLE0_FILENAME_T("NO_INIT"),
    .QC_TABLE1_FILENAME_T("NO_INIT"),
    .QC_TABLE2_FILENAME_T("NO_INIT"),
    .QC_TABLE3_FILENAME_T("NO_INIT"),
    .LA_TABLE_FILENAME("NO_INIT"),
    .LP_TABLE_FILENAME("NO_INIT"),
    .SC_TABLE_FILENAME("NO_INIT"),
    .CODE_TABLE0_FILENAME("NO_INIT"),
    .CODE_TABLE1_FILENAME("NO_INIT"),
    .CODE_TABLE2_FILENAME("NO_INIT"),
    .CODE_TABLE3_FILENAME("NO_INIT")
  ) inst (
    .reset_n(reset_n),
    .core_clk(core_clk),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bready(s_axi_bready),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rready(s_axi_rready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rvalid(s_axi_rvalid),
    .interrupt(interrupt),
    .s_axis_din_words_tready(),
    .s_axis_din_words_tvalid(1'B1),
    .s_axis_din_words_tlast(1'B1),
    .s_axis_din_words_tdata(8'D16),
    .s_axis_ctrl_tready(s_axis_ctrl_tready),
    .s_axis_ctrl_tvalid(s_axis_ctrl_tvalid),
    .s_axis_ctrl_tdata(s_axis_ctrl_tdata),
    .s_axis_din_tready(s_axis_din_tready),
    .s_axis_din_tvalid(s_axis_din_tvalid),
    .s_axis_din_tlast(s_axis_din_tlast),
    .s_axis_din_tdata(s_axis_din_tdata),
    .m_axis_status_tready(m_axis_status_tready),
    .m_axis_status_tvalid(m_axis_status_tvalid),
    .m_axis_status_tdata(m_axis_status_tdata),
    .s_axis_dout_words_tready(),
    .s_axis_dout_words_tvalid(1'B1),
    .s_axis_dout_words_tlast(1'B1),
    .s_axis_dout_words_tdata(8'D16),
    .m_axis_dout_tready(m_axis_dout_tready),
    .m_axis_dout_tvalid(m_axis_dout_tvalid),
    .m_axis_dout_tlast(m_axis_dout_tlast),
    .m_axis_dout_tdata(m_axis_dout_tdata)
  );
endmodule
