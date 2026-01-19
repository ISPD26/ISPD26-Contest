#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <design_name> <original_def> <revised_def> <original_ppa> <revised_ppa>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$1
ORIGINAL_DEF=$2
REVISED_DEF=$3
ORIGINAL_PPA=$4
REVISED_PPA=$5

# Wait for original PPA file to exist (with timeout)
echo "Waiting for original PPA file: $ORIGINAL_PPA"
WAIT_COUNT=0
MAX_WAIT=3000  # 50 minutes timeout
while [ ! -f "$ORIGINAL_PPA" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $((WAIT_COUNT % 30)) -eq 0 ]; then
        echo "Still waiting for original PPA file... (${WAIT_COUNT}s elapsed)"
    fi
done

if [ ! -f "$ORIGINAL_PPA" ]; then
    echo "Error: Original PPA file not found after waiting ${MAX_WAIT} seconds"
    echo "Expected file: $ORIGINAL_PPA"
    exit 1
fi

echo "Original PPA file found, proceeding with scoring..."

# Check if required files exist
REQUIRED_FILES=("$ORIGINAL_DEF" "$REVISED_DEF" "$ORIGINAL_PPA" "$REVISED_PPA" "./bin/calc_displacement")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: $file not found!"
        exit 1
    fi
done

echo "=========================================="
echo "Generating PPAD.out"
echo "=========================================="

# Extract revised metrics from revised PPA file
REVISED_TNS=$(grep "TNS:" "$REVISED_PPA" | awk '{print $2}')
REVISED_POWER=$(grep "Power:" "$REVISED_PPA" | awk '{print $2}')
REVISED_HPWL=$(grep "HPWL:" "$REVISED_PPA" | awk '{print $2}')

# Calculate displacement
echo "--- Calculating displacement ---"
REVISED_PPA_DIR=$(dirname "$REVISED_PPA")
DISPLACEMENT_LOG="${REVISED_PPA_DIR}/displacement.log"
./bin/calc_displacement "$ORIGINAL_DEF" "$REVISED_DEF" 2>&1 | tee "$DISPLACEMENT_LOG"

# Extract average displacement
AVG_DISPLACEMENT=$(grep "Average displacement per cell:" "$DISPLACEMENT_LOG" | awk '{print $6}')
if [ -z "$AVG_DISPLACEMENT" ]; then
    AVG_DISPLACEMENT="N/A"
fi

# Keep temporary file for debugging (do not remove)
# rm -f "$DISPLACEMENT_LOG"

# Generate PPAD.out file (PPA.out + Displacement)
PPAD_OUTPUT="${REVISED_PPA_DIR}/PPAD.out"
cat > "$PPAD_OUTPUT" << EOF
TNS: $REVISED_TNS
Power: $REVISED_POWER
HPWL: $REVISED_HPWL
Displacement: $AVG_DISPLACEMENT

EOF

echo "PPAD.out generated at: $PPAD_OUTPUT"
echo "Script completed."