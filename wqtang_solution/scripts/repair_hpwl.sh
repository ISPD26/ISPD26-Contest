#!/bin/bash

# Usage: ./scripts/repair_hpwl.sh <path>
# Example: ./scripts/repair_hpwl.sh ./database/des

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ./database/des"
    exit 1
fi

PATH_ARG="$1"

# Extract design name from the basename of the path
DESIGN=$(basename "$PATH_ARG")

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use fixed library path
LIB_PATH="$PROJECT_ROOT/testcases/ASAP7"

echo "Processing design: $DESIGN"
echo "Path: $PATH_ARG"
echo "Library path: $LIB_PATH"
echo ""

# Check if path exists
if [ ! -d "$PATH_ARG" ]; then
    echo "Error: Path does not exist: $PATH_ARG"
    exit 1
fi

# Activate conda environment if available
if command -v conda &> /dev/null; then
    source /opt/conda/etc/profile.d/conda.sh 2>/dev/null || true
    source /opt/conda/etc/profile.d/mamba.sh 2>/dev/null || true
    mamba activate probC_env 2>/dev/null || conda activate probC_env 2>/dev/null || true
fi

# Set Python path to include DREAMPlace
export PYTHONPATH="${PROJECT_ROOT}/extpkgs/DREAMPlace_install:${PYTHONPATH}"

# Counter for processed folders
PROCESSED=0
SKIPPED=0
FAILED=0

# Traverse each folder in the given path
for fold in "$PATH_ARG"/*/ ; do
    if [ ! -d "$fold" ]; then
        continue
    fi

    fold_name=$(basename "$fold")
    DEF_FILE="$fold/${DESIGN}.def"
    PPAD_FILE="$fold/PPAD.out"

    # Check if DEF file exists
    if [ ! -f "$DEF_FILE" ]; then
        echo "[$fold_name] Skipping - DEF file not found"
        ((SKIPPED++))
        continue
    fi

    # Check if PPAD.out exists
    if [ ! -f "$PPAD_FILE" ]; then
        echo "[$fold_name] Skipping - PPAD.out not found"
        ((SKIPPED++))
        continue
    fi

    echo "[$fold_name] Processing..."

    # Calculate HPWL using calc_hpwl.py
    HPWL_OUTPUT=$(python3 "$PROJECT_ROOT/extpkgs/DREAMPlace_install/dreamplace/CalcHPWL.py" -d "$DEF_FILE" -l "$LIB_PATH" --cuda 2>&1)

    # Write HPWL calculation log
    echo "$HPWL_OUTPUT" > "$fold/hpwl.log"

    if [ $? -eq 0 ]; then
        # Extract HPWL value from output
        HPWL=$(echo "$HPWL_OUTPUT" | grep "HPWL:" | awk '{print $2}')

        if [ -n "$HPWL" ]; then
            # Read old HPWL value
            OLD_HPWL=$(grep "^HPWL:" "$PPAD_FILE" | awk '{print $2}')

            # Update HPWL in PPAD.out
            sed -i "s/^HPWL:.*$/HPWL: $HPWL/" "$PPAD_FILE"

            echo "[$fold_name] Updated HPWL: $OLD_HPWL -> $HPWL"
            ((PROCESSED++))
        else
            echo "[$fold_name] Failed - Could not extract HPWL value from output"
            ((FAILED++))
        fi
    else
        echo "[$fold_name] Failed - HPWL calculation error:"
        echo "$HPWL_OUTPUT" | head -3
        ((FAILED++))
    fi
done

echo ""
echo "========================================="
echo "Summary:"
echo "  Processed: $PROCESSED"
echo "  Skipped:   $SKIPPED"
echo "  Failed:    $FAILED"
echo "========================================="
echo "Done!"
