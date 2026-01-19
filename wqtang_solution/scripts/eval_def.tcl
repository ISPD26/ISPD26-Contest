# OpenROAD Evaluation Script for ICCAD 2025 Problem C
puts "Starting evaluation for: {{DEF_FILE}}"

# Read Liberty files
puts "Reading Liberty files..."
foreach libFile [glob "{{LIB_PATH}}/LIB/*nldm*.lib"] {
    puts "Reading lib: $libFile"
    read_liberty $libFile
}

# Read sram Liberty files
# puts "Reading Liberty files..."
# foreach libFile [glob "{{LIB_PATH}}/LIB/sram*.lib"] {
#     puts "Reading lib: $libFile"
#     read_liberty $libFile
# }

# Read LEF files
puts "Reading LEF files..."
read_lef {{LIB_PATH}}/techlef/asap7_tech_1x_201209.lef
foreach lef [glob "{{LIB_PATH}}/LEF/*.lef"] {
    read_lef $lef
}

# Read design files
puts "Reading design files..."
read_def {{DEF_FILE}}
read_sdc {{SDC_FILE}}

# Set RC parasitics
source {{LIB_PATH}}/setRC.tcl
estimate_parasitics -placement

# Check placement legality
check_placement -verbose

# Report evaluation metrics
puts "\n=== Evaluation Results ==="
report_tns
report_wns
report_power
# report_design_area

# Save detailed reports
# report_checks -path_delay max > {{OUTPUT_PATH}}/timing_report.txt

exit