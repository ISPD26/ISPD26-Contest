#!/bin/bash

# Usage: ./scripts/replace_ppad_by_ppa.sh <path>
# Example: ./scripts/replace_ppad_by_ppa.sh ./database/ariane/
# This script traverses all folders in the given path and replaces TNS, Power, HPWL
# in PPAD.out with values from PPA.out in the same folder,
# while keeping the Displacement value from PPAD.out

# Check if path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ./database/ariane/"
    exit 1
fi

INPUT_PATH=$1

# Remove trailing slash if present
INPUT_PATH=${INPUT_PATH%/}

# Check if input path exists
if [ ! -d "$INPUT_PATH" ]; then
    echo "Error: Path '$INPUT_PATH' does not exist"
    exit 1
fi

echo "Processing path: $INPUT_PATH"
echo ""

# Counter for processed folders
processed=0
skipped=0
errors=0

# Iterate over subdirectories in the input path
for fold in "$INPUT_PATH"/*; do
    # Skip if not a directory
    if [ ! -d "$fold" ]; then
        continue
    fi

    # Get folder name
    folder_name=$(basename "$fold")

    # Define file paths
    PPAD_FILE="$fold/PPAD.out"
    PPA_FILE="$fold/PPA.out"

    # Check if both files exist
    if [ ! -f "$PPAD_FILE" ]; then
        echo "Skipping $folder_name: PPAD.out not found"
        ((skipped++))
        continue
    fi

    if [ ! -f "$PPA_FILE" ]; then
        echo "Skipping $folder_name: PPA.out not found"
        ((skipped++))
        continue
    fi

    echo "Processing: $folder_name"

    # Extract Displacement from PPAD.out
    DISPLACEMENT=$(grep "^Displacement:" "$PPAD_FILE" | awk '{print $2}')

    if [ -z "$DISPLACEMENT" ]; then
        echo "  Warning: Could not extract Displacement from PPAD.out, using 0.000000"
        DISPLACEMENT="0.000000"
    fi

    # Extract TNS from PPA.out
    TNS=$(grep "^TNS:" "$PPA_FILE" | awk '{print $2}')

    # Extract Total Power from PPA.out (try both "Power:" and "Total Power:" formats)
    POWER=$(grep "^Total Power:" "$PPA_FILE" | awk '{print $3}')
    if [ -z "$POWER" ]; then
        POWER=$(grep "^Power:" "$PPA_FILE" | awk '{print $2}')
    fi

    # Extract HPWL from PPA.out
    HPWL=$(grep "^HPWL:" "$PPA_FILE" | awk '{print $2}')

    # If HPWL not found in PPA.out, keep the original from PPAD.out
    if [ -z "$HPWL" ]; then
        HPWL=$(grep "^HPWL:" "$PPAD_FILE" | awk '{print $2}')
        if [ -z "$HPWL" ]; then
            HPWL="N/A"
        fi
    fi

    # Validate extracted values
    if [ -z "$TNS" ] || [ -z "$POWER" ]; then
        echo "  Error: Could not extract TNS or Power from PPA.out"
        ((errors++))
        continue
    fi

    # Create backup of original PPAD.out
    cp "$PPAD_FILE" "${PPAD_FILE}.bak"

    # Write updated PPAD.out
    cat > "$PPAD_FILE" << EOF
TNS: $TNS
Power: $POWER
HPWL: $HPWL
Displacement: $DISPLACEMENT
EOF

    echo "  ✓ Updated: TNS=$TNS, Power=$POWER, HPWL=$HPWL, Displacement=$DISPLACEMENT"
    ((processed++))
done

echo ""
echo "Summary:"
echo "  Processed: $processed folders"
echo "  Skipped: $skipped folders"
echo "  Errors: $errors folders"
echo ""
echo "Note: Original PPAD.out files have been backed up as PPAD.out.bak"
