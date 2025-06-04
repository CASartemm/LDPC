onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+ldpc_0  -L xilinx_vip -L ecc_v2_0_13 -L fec_5g_common_v1_1_1 -L ldpc_v2_0_11 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ldpc_0 xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {ldpc_0.udo}

run 1000ns

endsim

quit -force
