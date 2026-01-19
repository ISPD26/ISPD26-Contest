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

# Activate conda environment if available (for HPWL calculation)
if command -v conda &> /dev/null; then
    source /opt/conda/etc/profile.d/conda.sh
    source /opt/conda/etc/profile.d/mamba.sh
    mamba activate probC_env 2>/dev/null || conda activate probC_env 2>/dev/null || true
fi

# Set Python path to include DREAMPlace (for HPWL calculation)
export PYTHONPATH="${PROJECT_ROOT}/extpkgs/DREAMPlace_install:${PYTHONPATH}"

# Calculate HPWL using enhanced DREAMPlace calculator
HPWL_OUTPUT=$(python3 "${PROJECT_ROOT}/extpkgs/DREAMPlace_install/dreamplace/CalcHPWL.py" -d "$DEF_FILE" -l "$LIB_PATH" --cuda 2>&1)
if [ $? -eq 0 ]; then
    HPWL=$(echo "$HPWL_OUTPUT" | grep "HPWL:" | awk '{print $2}')
    # Write detailed HPWL calculation log
    echo "$HPWL_OUTPUT" > "${OUTPUT_PATH}/hpwl.log"
else
    echo "Warning: HPWL calculation failed: $HPWL_OUTPUT"
    echo "$HPWL_OUTPUT" > "${OUTPUT_PATH}/hpwl.log"
    HPWL="N/A"
fi

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

# Total Power is in the last "Total" row before the percentage breakdown
# Looking for the line that starts with "Total" and extracting the 5th column (Total Power)
POWER=$(grep -A20 "=== Evaluation Results ===" ${OUTPUT_PATH}/eval.log | grep "^Total" | head -1 | awk '{print $5}')

# Alternative method if the above doesn't work reliably:
# POWER=$(awk '/^Total/ && NF==6 {print $5}' ${OUTPUT_PATH}/eval.log | tail -1)

# Output simplified metrics to PPA.out
cat > "${OUTPUT_PATH}/PPA.out" << EOF
TNS: $TNS
Power: $POWER
HPWL: $HPWL
WNS: $WNS
EOF

# Also echo to console for immediate feedback
echo "TNS: $TNS"
echo "Power: $POWER"
echo "HPWL: $HPWL"
echo "WNS: $WNS"

# Optional: Add validation to check if values were extracted correctly
if [ -z "$TNS" ] || [ -z "$WNS" ] || [ -z "$POWER" ]; then
    echo "Error: Failed to extract some metrics from the log file"
    echo "Please check ${OUTPUT_PATH}/eval.log for the actual output format"
    exit 1
fi