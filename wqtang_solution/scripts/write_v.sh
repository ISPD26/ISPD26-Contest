#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <design_name> <input path> <output path>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$(basename $1)
INPUT_PATH=$(realpath "$2")
OUTPUT_PATH=$3
mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$(realpath "$3")

ASAP7_PATH=$(realpath "./testcases/ASAP7")
INPUT_DEF=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.def")
INPUT_SDC=$(realpath "./testcases/${DESIGN_NAME}/${DESIGN_NAME}.sdc")

# Generate OpenROAD optimization script with variable substitution
cat > "${OUTPUT_PATH}/write_v.tcl" << EOF
puts "Starting optimization for: $INPUT_DEF"

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

# Write output files
write_verilog $OUTPUT_PATH/$DESIGN_NAME.v

puts "\n=== Optimization Complete ==="
puts "Output VERILOG written to: $OUTPUT_PATH/$DESIGN_NAME.v"

exit
EOF

# Run OpenROAD 
echo "Running OpenROAD ..."
openroad -exit ${OUTPUT_PATH}/write_v.tcl 2>&1 > ${OUTPUT_PATH}/write_v.log