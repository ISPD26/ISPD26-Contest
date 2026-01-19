#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <input def> <input sdc> <output v>"
    exit 1
fi

# Parse arguments
INPUT_DEF=$(realpath "$1")
INPUT_SDC=$(realpath "$2")
OUTPUT_V=$(realpath "$3")

# Get output directory
OUTPUT_DIR=$(dirname "$OUTPUT_V")
mkdir -p "$OUTPUT_DIR"

ASAP7_PATH=$(realpath "./testcases/ASAP7")

# Generate OpenROAD script with variable substitution
cat > "${OUTPUT_DIR}/write_v.tcl" << EOF
puts "Generating Verilog from: $INPUT_DEF"

# Read Liberty files
puts "Reading Liberty files..."
foreach libFile [glob "$ASAP7_PATH/LIB/*nldm*.lib"] {
    puts "Reading lib: \$libFile"
    read_liberty \$libFile
}

# Read Liberty sram files
puts "Reading Liberty files..."
foreach libFile [glob "$ASAP7_PATH/LIB/sram*.lib"] {
    puts "Reading lib: \$libFile"
    read_liberty \$libFile
}

# Read LEF files
puts "Reading LEF files..."
read_lef $ASAP7_PATH/techlef/asap7_tech_1x_201209.lef
foreach lef [glob "$ASAP7_PATH/LEF/*.lef"] {
    read_lef \$lef
}

# Read design files
puts "Reading design files..."
read_def $INPUT_DEF
read_sdc $INPUT_SDC

# Set RC parasitics
source $ASAP7_PATH/setRC.tcl
estimate_parasitics -placement

# Write output file
write_verilog $OUTPUT_V

puts "\n=== Verilog Generation Complete ==="
puts "Output VERILOG written to: $OUTPUT_V"

exit
EOF

# Run OpenROAD
echo "Running OpenROAD to generate Verilog..."
openroad -exit ${OUTPUT_DIR}/write_v.tcl 2>&1 > ${OUTPUT_DIR}/write_v.log
