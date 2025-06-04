vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/ecc_v2_0_13
vlib modelsim_lib/msim/fec_5g_common_v1_1_1
vlib modelsim_lib/msim/ldpc_v2_0_11
vlib modelsim_lib/msim/xil_defaultlib

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap ecc_v2_0_13 modelsim_lib/msim/ecc_v2_0_13
vmap fec_5g_common_v1_1_1 modelsim_lib/msim/fec_5g_common_v1_1_1
vmap ldpc_v2_0_11 modelsim_lib/msim/ldpc_v2_0_11
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xilinx_vip  -incr -mfcu  -sv -L fec_5g_common_v1_1_1 -L ldpc_v2_0_11 "+incdir+M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work ecc_v2_0_13  -incr -mfcu  "+incdir+../../../ipstatic/hdl" "+incdir+../../../../ip_core.gen/sources_1/ip/ldpc_0/drivers/ldpc_v2_0/src" "+incdir+M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../ipstatic/hdl/ecc_v2_0_vl_rfs.v" \

vlog -work fec_5g_common_v1_1_1  -incr -mfcu  -sv -L fec_5g_common_v1_1_1 -L ldpc_v2_0_11 "+incdir+../../../ipstatic/hdl" "+incdir+../../../../ip_core.gen/sources_1/ip/ldpc_0/drivers/ldpc_v2_0/src" "+incdir+M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../ipstatic/hdl/fec_5g_common_v1_1_rfs.sv" \

vlog -work ldpc_v2_0_11  -incr -mfcu  -sv -L fec_5g_common_v1_1_1 -L ldpc_v2_0_11 "+incdir+../../../ipstatic/hdl" "+incdir+../../../../ip_core.gen/sources_1/ip/ldpc_0/drivers/ldpc_v2_0/src" "+incdir+M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../ipstatic/hdl/ldpc_v2_0_rfs.sv" \

vlog -work xil_defaultlib  -incr -mfcu  -sv -L fec_5g_common_v1_1_1 -L ldpc_v2_0_11 "+incdir+../../../ipstatic/hdl" "+incdir+../../../../ip_core.gen/sources_1/ip/ldpc_0/drivers/ldpc_v2_0/src" "+incdir+M:/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../ip_core.gen/sources_1/ip/ldpc_0/sim/ldpc_0.sv" \

vlog -work xil_defaultlib \
"glbl.v"

