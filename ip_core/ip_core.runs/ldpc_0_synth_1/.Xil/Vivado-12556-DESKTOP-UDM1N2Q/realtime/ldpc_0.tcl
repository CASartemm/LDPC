# 
# Synthesis run script generated by Vivado
# 

namespace eval rt {
    variable rc
}
set rt::rc [catch {
  uplevel #0 {
    set ::env(BUILTIN_SYNTH) true
    source $::env(HRT_TCL_PATH)/rtSynthPrep.tcl
    rt::HARTNDb_startJobStats
    set rt::cmdEcho 0
    rt::set_parameter writeXmsg true
    rt::set_parameter enableParallelHelperSpawn true
    set ::env(RT_TMP) "C:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.runs/ldpc_0_synth_1/.Xil/Vivado-12556-DESKTOP-UDM1N2Q/realtime/tmp"
    if { [ info exists ::env(RT_TMP) ] } {
      file mkdir $::env(RT_TMP)
    }

    rt::delete_design

    rt::set_parameter datapathDensePacking false
    set rt::partid xc7vx485tffg1157-1
     file delete -force synth_hints.os

    set rt::multiChipSynthesisFlow false
    source $::env(SYNTH_COMMON)/common.tcl
    set rt::defaultWorkLibName xil_defaultlib

    # Skipping read_* RTL commands because this is post-elab optimize flow
    set rt::useElabCache true
    if {$rt::useElabCache == false} {
      rt::read_verilog -sv -include {
    c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/hdl
    c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0
  } {
      c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/hdl/fec_5g_common_v1_1_rfs.sv
      c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/hdl/ldpc_v2_0_rfs.sv
      c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/synth/ldpc_0.sv
    }
      rt::read_verilog -include {
    c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/hdl
    c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0
  } c:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.gen/sources_1/ip/ldpc_0/hdl/ecc_v2_0_vlsyn_rfs.v
      rt::filesetChecksum
    }
    rt::set_parameter usePostFindUniquification true
    set rt::SDCFileList C:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.runs/ldpc_0_synth_1/.Xil/Vivado-12556-DESKTOP-UDM1N2Q/realtime/ldpc_0_synth.xdc
    rt::sdcChecksum
    set rt::top ldpc_0
    rt::set_parameter enableIncremental true
    rt::set_parameter markDebugPreservationLevel "enable"
    set rt::ioInsertion false
    set rt::reportTiming false
    rt::set_parameter elaborateOnly false
    rt::set_parameter elaborateRtl false
    rt::set_parameter eliminateRedundantBitOperator true
    rt::set_parameter dataflowBusHighlighting false
    rt::set_parameter generateDataflowBusNetlist false
    rt::set_parameter dataFlowViewInElab false
    rt::set_parameter busViewFixBrokenConnections false
    rt::set_parameter elaborateRtlOnlyFlow false
    rt::set_parameter writeBlackboxInterface true
    rt::set_parameter ramStyle auto
    rt::set_parameter merge_flipflops true
# MODE: out_of_context
    rt::set_parameter webTalkPath {}
    rt::set_parameter synthDebugLog false
    rt::set_parameter printModuleName false
    rt::set_parameter enableSplitFlowPath "C:/Users/arty/Documents/GitHub/LDPC/ip_core/ip_core.runs/ldpc_0_synth_1/.Xil/Vivado-12556-DESKTOP-UDM1N2Q/"
    set ok_to_delete_rt_tmp true 
    if { [rt::get_parameter parallelDebug] } { 
       set ok_to_delete_rt_tmp false 
    } 
    if {$rt::useElabCache == false} {
        set oldMIITMVal [rt::get_parameter maxInputIncreaseToMerge]; rt::set_parameter maxInputIncreaseToMerge 1000
        set oldCDPCRL [rt::get_parameter createDfgPartConstrRecurLimit]; rt::set_parameter createDfgPartConstrRecurLimit 1
        $rt::db readXRFFile
      rt::run_synthesis -module $rt::top
        rt::set_parameter maxInputIncreaseToMerge $oldMIITMVal
        rt::set_parameter createDfgPartConstrRecurLimit $oldCDPCRL
    }

    set rt::flowresult [ source $::env(SYNTH_COMMON)/flow.tcl ]
    rt::HARTNDb_stopJobStats
    rt::HARTNDb_reportJobStats "Synthesis Optimization Runtime"
    rt::HARTNDb_stopSystemStats
    rt::close_pss_mem_watcher
    if { $rt::flowresult == 1 } { return -code error }


  set hsKey [rt::get_parameter helper_shm_key] 
  if { $hsKey != "" && [info exists ::env(BUILTIN_SYNTH)] && [rt::get_parameter enableParallelHelperSpawn] } { 
     $rt::db killSynthHelper $hsKey
  } 
  rt::set_parameter helper_shm_key "" 
    if { [ info exists ::env(RT_TMP) ] } {
      if { [info exists ok_to_delete_rt_tmp] && $ok_to_delete_rt_tmp } { 
        file delete -force $::env(RT_TMP)
      }
    }

    source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  } ; #end uplevel
} rt::result]

if { $rt::rc } {
  $rt::db resetHdlParse
  set hsKey [rt::get_parameter helper_shm_key] 
  if { $hsKey != "" && [info exists ::env(BUILTIN_SYNTH)] && [rt::get_parameter enableParallelHelperSpawn] } { 
     $rt::db killSynthHelper $hsKey
  } 
  source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  return -code "error" $rt::result
}
