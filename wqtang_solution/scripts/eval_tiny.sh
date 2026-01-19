#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <def_file> <sdc_file> <lib_path> <output path>"
    exit 1
fi

# Parse arguments
DEF_FILE=$1
SDC_FILE=$2
LIB_PATH=$3
OUTPUT_PATH=$4

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create output directory
mkdir -p $OUTPUT_PATH

# Generate evaluation TCL script with variable substitution
sed -e "s|{{LIB_PATH}}|$LIB_PATH|g" \
    -e "s|{{DEF_FILE}}|$DEF_FILE|g" \
    -e "s|{{SDC_FILE}}|$SDC_FILE|g" \
    -e "s|{{OUTPUT_PATH}}|$OUTPUT_PATH|g" \
    ./scripts/eval_def.tcl > ${OUTPUT_PATH}/eval_generated.tcl

# Run OpenROAD evaluation
openroad -no_init -exit ${OUTPUT_PATH}/eval_generated.tcl 2>&1 | tee ${OUTPUT_PATH}/eval.log > /dev/null

# Extract metrics from log
# TNS and WNS are on separate lines after "=== Evaluation Results ==="
TNS=$(grep -A2 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^tns" | awk '{print $2}')
WNS=$(grep -A3 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^wns" | awk '{print $2}')

# Extract power details from the Total row in the power table
# The Total row contains: Internal Power, Switching Power, Leakage Power, Total Power
INTERNAL_POWER=$(grep -A20 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^Total" | head -1 | awk '{print $2}')
SWITCHING_POWER=$(grep -A20 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^Total" | head -1 | awk '{print $3}')
LEAKAGE_POWER=$(grep -A20 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^Total" | head -1 | awk '{print $4}')
TOTAL_POWER=$(grep -A20 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^Total" | head -1 | awk '{print $5}')

# Output detailed metrics to PPA.out in the requested format
cat > "${OUTPUT_PATH}/PPA.out" << EOF
WNS: $WNS
TNS: $TNS
Internal Power: $INTERNAL_POWER
Switching Power: $SWITCHING_POWER
Leakage Power: $LEAKAGE_POWER
Total Power: $TOTAL_POWER
EOF

# Also echo to console for immediate feedback
echo "WNS: $WNS"
echo "TNS: $TNS"
echo "Internal Power: $INTERNAL_POWER"
echo "Switching Power: $SWITCHING_POWER"
echo "Leakage Power: $LEAKAGE_POWER"
echo "Total Power: $TOTAL_POWER"

# Optional: Add validation to check if values were extracted correctly
if [ -z "$TNS" ] || [ -z "$WNS" ] || [ -z "$INTERNAL_POWER" ] || [ -z "$SWITCHING_POWER" ] || [ -z "$LEAKAGE_POWER" ] || [ -z "$TOTAL_POWER" ]; then
    echo "Error: Failed to extract some metrics from the log file"
    echo "Please check ${OUTPUT_PATH}/eval.log for the actual output format"
    exit 1
fi