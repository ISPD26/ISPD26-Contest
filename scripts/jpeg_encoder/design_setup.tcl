
set sdc_file ${top_proj_dir}/Benchmarks/${design_name}/${folder}/contest.sdc

# Replace the original .def and .v files with your modified versions (i.e., the outputs of your developed tool) to evaluate your tool's performance.
set def_file ${out_dir}/${design_name}.def
set verilog_netlist ${out_dir}/${design_name}.v
