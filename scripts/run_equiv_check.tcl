set design_name     "$::env(DESIGN_NAME)"
set folder $::env(FOLDER_NAME)
set top_proj_dir    "$::env(TOP_PROJ_DIR)"
set proj_dir        "$::env(PROJ_DIR)"

source lib_setup.tcl
source design_setup_baseline.tcl
source or_utils.tcl

## Read lef and lib files
foreach lef_file ${lefs}    { read_lef     $lef_file }
foreach lib_file ${libbest} { read_liberty $lib_file }

## Read the design
read_def ${def_file}
read_sdc ${sdc_file}

source $rc_file

set node_file ./${folder}/node.csv
set net_file ./${folder}/nets.csv

write_node_and_net_files $node_file $net_file

puts "Script completed successfully"


