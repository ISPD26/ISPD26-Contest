read_lef  __TECH_DIR__/lef/asap7_tech_1x_201209.lef

foreach lef [lsort [glob -nocomplain __TECH_DIR__/lef/asap7sc7p5t_28_*_1x_220121a.lef]] {
  read_lef $lef
}
foreach lef [lsort [glob -nocomplain __TECH_DIR__/lef/sram_asap7_*.lef]] {
  read_lef $lef
}
read_lef __TECH_DIR__/lef/fakeram_256x64.lef

foreach lib [lsort [glob -nocomplain __TECH_DIR__/lib/asap7sc7p5t_*.lib]] {
  read_liberty $lib
}
foreach lib [lsort [glob -nocomplain __TECH_DIR__/lib/sram_asap7_*.lib]] {
  read_liberty $lib
}
read_liberty __TECH_DIR__/lib/fakeram_256x64.lib


set rc_file __TECH_DIR__/util/setRC.tcl
