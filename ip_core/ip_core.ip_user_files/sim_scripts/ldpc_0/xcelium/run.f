-makelib xcelium_lib/xilinx_vip -sv \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/ecc_v2_0_13 \
  "../../../ipstatic/hdl/ecc_v2_0_vl_rfs.v" \
-endlib
-makelib xcelium_lib/fec_5g_common_v1_1_1 -sv \
  "../../../ipstatic/hdl/fec_5g_common_v1_1_rfs.sv" \
-endlib
-makelib xcelium_lib/ldpc_v2_0_11 -sv \
  "../../../ipstatic/hdl/ldpc_v2_0_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../ip_core.gen/sources_1/ip/ldpc_0/sim/ldpc_0.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

