#!/bin/bash

# Check if path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ./training_set/aes"
    exit 1
fi

PATH_ARG=$1

# Check if path exists
if [ ! -d "$PATH_ARG" ]; then
    echo "Error: Directory $PATH_ARG not found!"
    exit 1
fi

DESIGN_NAME=$(basename "$PATH_ARG")
echo "Design name: $DESIGN_NAME"

echo "=========================================="
echo "generating verilog and sdc for all def files"
echo "=========================================="

# Counter for tracking progress
PROCESSED=0
TOTAL=0

# Count total folders to process
for fold in "$PATH_ARG"/*; do
    if [ -d "$fold" ]; then
        TOTAL=$((TOTAL + 1))
    fi
done

echo "Found $TOTAL solution folders to process"
echo

# Get the absolute paths for the library
ASAP7_PATH=$(realpath "./testcases/ASAP7")

# Traverse every folder in the path
for fold in "$PATH_ARG"/*; do
    if [ -d "$fold" ]; then
        FOLD_NAME=$(basename "$fold")
        PROCESSED=$((PROCESSED + 1))

        echo "[$PROCESSED/$TOTAL] Processing fold: $FOLD_NAME"

        # Check if DEF file exists in this fold
        DEF_FILE="$fold/$DESIGN_NAME.def"
        if [ ! -f "$DEF_FILE" ]; then
            echo "  Warning: DEF file not found: $DEF_FILE"
            continue
        fi

        # Check if SDC file exists in this fold, if not copy from original
        SDC_FILE="$fold/$DESIGN_NAME.sdc"
        if [ ! -f "$SDC_FILE" ]; then
            ORIGINAL_SDC="$PATH_ARG/original/$DESIGN_NAME.sdc"
            if [ -f "$ORIGINAL_SDC" ]; then
                echo "  Copying SDC from original folder..."
                cp "$ORIGINAL_SDC" "$fold/"
            else
                echo "  Warning: SDC file not found in fold or original: $SDC_FILE"
                continue
            fi
        fi

        # Generate .v file using write_v.sh
        V_FILE="$fold/$DESIGN_NAME.v"
        if [ -f "$V_FILE" ]; then
            echo "  ⊘ Skipping .v generation (already exists)"
        else
            echo "  Generating .v file..."
            ./scripts/write_v.sh "$DESIGN_NAME" "$fold" "$fold" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "  Error: Failed to generate .v file for $FOLD_NAME"
                continue
            fi
        fi

        # Generate PPA.out using eval_tiny.sh
        PPA_FILE="$fold/PPA.out"
        if [ -f "$PPA_FILE" ]; then
            echo "  ⊘ Skipping PPA.out generation (already exists)"
        else
            echo "  Generating PPA.out..."
            ./scripts/eval_tiny.sh "$DEF_FILE" "$SDC_FILE" "$ASAP7_PATH" "$fold" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "  Error: Failed to generate PPA.out for $FOLD_NAME"
                continue
            fi
        fi

        # Clean up .tcl and .log files
        echo "  Cleaning up .tcl and .log files..."
        rm -f "$fold"/*.tcl "$fold"/*.log

        echo "  ✓ Successfully processed $FOLD_NAME"
    fi
done

echo
echo "=========================================="
echo "Processing complete!"
echo "Processed $PROCESSED/$TOTAL solution folders"
echo "=========================================="
