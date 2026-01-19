#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 6 ]; then
    echo "Usage: $0 <design_name> <TNS_weight, alpha> <power_weight, beta> <HPWL_weight, gamma> <input path> <output path>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$(basename $1)
ALPHA=$2
BETA=$3
GAMMA=$4
INPUT_PATH=$(realpath "$5")
OUTPUT_PATH=$6
mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$(realpath "$6")

ASAP7_PATH=$(realpath "./testcases/ASAP7")
INPUT_DEF=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.def")
INPUT_VERILOG=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.v")
INPUT_SDC=$(realpath "./testcases/${DESIGN_NAME}/${DESIGN_NAME}.sdc")

# Generate OpenROAD optimization script with variable substitution
cat > "${OUTPUT_PATH}/optimize.tcl" << EOF
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

# global_placement

# Perform repair timing optimization
puts "\n=== Starting Repair Timing Optimization ==="
repair_timing -setup \\
    -skip_pin_swap \\
    -skip_gate_cloning \\
    -skip_buffer_removal \\
    -verbose


# Perform detailed placement
puts "\n=== Starting Detailed Placement ==="
detailed_placement

# Write output files
puts "\n=== Writing Output Files ==="
write_def $OUTPUT_PATH/$DESIGN_NAME.def
write_verilog $OUTPUT_PATH/$DESIGN_NAME.v

puts "\n=== Optimization Complete ==="
puts "Output DEF written to: $OUTPUT_PATH/$DESIGN_NAME.def"
puts "Output VERILOG written to: $OUTPUT_PATH/$DESIGN_NAME.v"

exit
EOF

# Run OpenROAD optimization
echo "Running OpenROAD optimization..."
openroad -exit ${OUTPUT_PATH}/optimize.tcl 2>&1 > ${OUTPUT_PATH}/optimize.log


# Check if optimization was successful
OUTPUT_DEF=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.def")
OUTPUT_CHANGELIST=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.changelist")
if [ $? -eq 0 ]; then
    echo "Optimization completed successfully!"
    # Output DEF file should be in results directory
    if [ -f "$OUTPUT_DEF" ]; then
        OUTPUT_PARENT_PATH=$(dirname $OUTPUT_PATH)
        ORIGINAL_DEF="${OUTPUT_PARENT_PATH}/original/${DESIGN_NAME}.def"

        ./bin/gen_changelist "${ORIGINAL_DEF}" "${OUTPUT_DEF}" "${OUTPUT_CHANGELIST}"
        echo "Optimized DEF file: ${OUTPUT_DEF}"
        echo "Optimized CHANGELIST file: ${OUTPUT_CHANGELIST}"
        ./scripts/eval.sh "${OUTPUT_DEF}" ${INPUT_SDC} ${ASAP7_PATH} ${OUTPUT_PATH}
        
        # Call write_ans.sh to handle scoring and solution updates
        ./scripts/write_ans.sh "${DESIGN_NAME}" "${ORIGINAL_DEF}" "${OUTPUT_PATH}"
    else
        echo "Error: Optimized DEF file not found!"
        exit 1
    fi
else
    echo "Error: OpenROAD optimization failed!"
    exit 1
fi
