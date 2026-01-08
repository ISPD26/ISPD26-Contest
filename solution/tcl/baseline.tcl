
# ===============================
# ISPD26 OpenROAD Baseline Flow
# ===============================

set design_name $::env(DESIGN_NAME)
set tech_dir    $::env(TECH_DIR)
set design_dir  $::env(DESIGN_DIR)
set out_dir     $::env(OUTPUT_DIR)

set start [clock seconds]

# -------------------------------
# 1) Read LEF / LIB
# -------------------------------
read_lef  $tech_dir/lef/asap7_tech_1x_201209.lef

foreach lef [lsort [glob -nocomplain $tech_dir/lef/asap7sc7p5t_28_*_1x_220121a.lef]] {
  read_lef $lef
}
foreach lef [lsort [glob -nocomplain $tech_dir/lef/sram_asap7_*.lef]] {
  read_lef $lef
}
read_lef $tech_dir/lef/fakeram_256x64.lef

foreach lib [lsort [glob -nocomplain $tech_dir/lib/asap7sc7p5t_*.lib]] {
  read_liberty $lib
}
foreach lib [lsort [glob -nocomplain $tech_dir/lib/sram_asap7_*.lib]] {
  read_liberty $lib
}
read_liberty $tech_dir/lib/fakeram_256x64.lib

# -------------------------------
# 2) Read design
#    ⚠️ DEF 會建立 block
# -------------------------------
read_verilog $design_dir/contest.v
read_def     $design_dir/contest.def
read_sdc     $design_dir/contest.sdc

# -------------------------------
# 3) RC model
# -------------------------------
set_ideal_network [all_clocks]

set end_setting [clock seconds]

source $tech_dir/util/setRC.tcl
estimate_parasitics -placement

# Keep units exactly as requested
set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um
set_units -power mW

set start_rsz [clock seconds]
# -------------------------------
# 4) Baseline resizer
# -------------------------------
puts "\[INFO\] Start OpenROAD RSZ ..."

repair_design
repair_timing -setup -skip_gate_cloning -skip_pin_swap 
detailed_placement

# -------------------------------
# 5) Write outputs
# -------------------------------
set end_rsz [clock seconds]
puts "\[INFO\] OR RSZ runtime:   [expr {$end_rsz - $start_rsz}] second"

write_verilog $out_dir/$design_name.v
write_def     $out_dir/$design_name.def

exit
TCL