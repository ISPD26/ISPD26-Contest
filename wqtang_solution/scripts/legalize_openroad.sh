#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <input def> <input verilog> <input sdc> <output def>"
    exit 1
fi

# Parse arguments
INPUT_DEF=$(realpath "$1")
INPUT_VERILOG=$(realpath "$2")
INPUT_SDC=$(realpath "$3")
OUTPUT_DEF=$(realpath "$4")

# Get directory for output
OUTPUT_DIR=$(dirname "$OUTPUT_DEF")
mkdir -p "$OUTPUT_DIR"

ASAP7_PATH=$(realpath "./testcases/ASAP7")

LOG_FILE="${OUTPUT_DIR}/openroad.log"

# Generate OpenROAD legalization script (detailed_placement only)
cat > "${OUTPUT_DIR}/legalize.tcl" << EOF
puts "Starting legalization for: $INPUT_DEF"

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

# Perform detailed placement (legalization only)
puts "\n=== Starting Detailed Placement (Legalization) ==="
detailed_placement

# Write output files
puts "\n=== Writing Output Files ==="
write_def $OUTPUT_DEF

puts "\n=== Legalization Complete ==="
puts "Output DEF written to: $OUTPUT_DEF"

exit
EOF

# Run OpenROAD legalization
echo "Running OpenROAD legalization (detailed_placement only)..."
timeout 600 openroad -exit ${OUTPUT_DIR}/legalize.tcl 2>&1 > ${LOG_FILE}

# Check if legalization was successful
if [ $? -eq 0 ] && [ -f "$OUTPUT_DEF" ]; then
    echo "Legalization completed successfully!"
    echo "Legalized DEF file: ${OUTPUT_DEF}"
    exit 0
else
    echo "Error: OpenROAD legalization failed!"
    exit 1
fi
