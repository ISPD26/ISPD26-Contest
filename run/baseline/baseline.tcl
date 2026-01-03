
# ===============================
# ISPD26 OpenROAD Baseline Flow
# ===============================

set design_name $::env(DESIGN_NAME)
set tech_dir    $::env(TECH_DIR)
set design_dir  $::env(DESIGN_DIR)
set out_dir     $::env(OUTPUT_DIR)

# -------------------------------
# 1) Read LEF / LIB
# -------------------------------
read_lef  $tech_dir/lef/asap7_tech_1x_201209.lef

foreach lef [glob -nocomplain $tech_dir/lef/asap7sc7p5t_28_*_1x_220121a.lef] {
  read_lef $lef
}
foreach lef [glob -nocomplain $tech_dir/lef/sram_asap7_*.lef] {
  read_lef $lef
}
read_lef $tech_dir/lef/fakeram_256x64.lef
foreach lib [glob -nocomplain $tech_dir/lib/*.lib] {
  read_liberty $lib
}

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
source $tech_dir/util/setRC.tcl

# -------------------------------
# 4) Baseline resizer
# -------------------------------
repair_design
repair_timing
detailed_placement

# -------------------------------
# 5) Write outputs
# -------------------------------
write_verilog $out_dir/contest.v
write_def     $out_dir/contest.def

exit
TCL