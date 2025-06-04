package require yaml
load librdi_iptasks[info sharedlibextension] ;# Load IP helper functions

proc gen_ldpc_code_params { code_yml } {

  set fc [read [set fh [open $code_yml "r"]]]
  close $fh
  
  set specs [::yaml::yaml2dict $fc]
  
  set params [ldpc::gen_ldpc_params $specs]
  set code_ids [dict keys [dict get $params config]]
  puts "gen_ldpc_code_params: Parameters generated for codes: [join $code_ids {,}]"
  foreach code_id $code_ids {
    puts "gen_ldpc_code_params: $code_id: "
    puts "  k: [dict get $params config $code_id k]"
    puts "  n: [dict get $params config $code_id n]"
    puts "  p: [dict get $params config $code_id p]"
    puts "  sc_table size: [llength [dict get $params config $code_id sc_table]]"
    puts "  la_table size: [llength [dict get $params config $code_id la_table]]"
    puts "  qc_table size: [llength [dict get $params config $code_id qc_table]]"
  }
  # gen_ldpc_params returns a dict with top-level keys: config, transactions & messages
  # o Just return config
  return [dict get $params config]
}
