#!/bin/bash

# Check if path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ./database/aes"
    exit 1
fi

PATH_ARG=$1

# Check if path exists
if [ ! -d "$PATH_ARG" ]; then
    echo "Error: Directory $PATH_ARG not found!"
    exit 1
fi

# Check if original directory exists
ORIGINAL_DIR="${PATH_ARG}/original"
if [ ! -d "$ORIGINAL_DIR" ]; then
    echo "Error: Original directory $ORIGINAL_DIR not found!"
    exit 1
fi

DESIGN_NAME=$(basename "$PATH_ARG")
ORIGINAL_DEF=$ORIGINAL_DIR/$DESIGN_NAME.def
echo "Design name: $DESIGN_NAME"
echo "Original DEF: $ORIGINAL_DEF"

# Check if gen_changelist binary exists
if [ ! -f "./bin/gen_changelist" ]; then
    echo "Error: ./bin/gen_changelist not found!"
    exit 1
fi

echo "=========================================="
echo "Updating changelist for all solutions"
echo "=========================================="

# Counter for tracking progress
PROCESSED=0
TOTAL=0

# Count total folders to process (excluding original)
for fold in "$PATH_ARG"/*; do
    if [ -d "$fold" ] && [ "$(basename "$fold")" != "original" ]; then
        TOTAL=$((TOTAL + 1))
    fi
done

echo "Found $TOTAL solution folders to process"
echo

# Traverse every folder in the path (excluding original)
for fold in "$PATH_ARG"/*; do
    if [ -d "$fold" ] && [ "$(basename "$fold")" != "original" ]; then
        FOLD_NAME=$(basename "$fold")
        REVISED_DEF="${fold}/${DESIGN_NAME}.def"
        
        echo "Processing folder: $FOLD_NAME"
        
        # Check if revised DEF file exists
        if [ ! -f "$REVISED_DEF" ]; then
            echo "  Warning: $REVISED_DEF not found, skipping"
            continue
        fi
        
        
        # Generate changelist
        echo "  Generating changelist..."
        CHANGELIST_FILE="${fold}/${DESIGN_NAME}.changelist"
        CHANGELIST_NEW="${fold}/${DESIGN_NAME}.changelist.new"
        
        # Generate new changelist
        ./bin/gen_changelist "$ORIGINAL_DEF" "$REVISED_DEF" "$CHANGELIST_NEW"
        
        if [ ! -f "$CHANGELIST_NEW" ]; then
            echo "  Warning: Could not generate changelist, skipping"
            continue
        fi
        
        # Compare with existing changelist if it exists
        if [ -f "$CHANGELIST_FILE" ]; then
            if cmp -s "$CHANGELIST_FILE" "$CHANGELIST_NEW"; then
                echo "  The changelist is same"
                rm "$CHANGELIST_NEW"
            else
                echo "  Changelist updated"
                mv "$CHANGELIST_NEW" "$CHANGELIST_FILE"
            fi
        else
            echo "  New changelist created"
            mv "$CHANGELIST_NEW" "$CHANGELIST_FILE"
        fi
        
        
        PROCESSED=$((PROCESSED + 1))
        echo "  Progress: $PROCESSED/$TOTAL completed"
        echo
    fi
done

echo "=========================================="
echo "Changelist update completed!"
echo "Processed $PROCESSED solution folders"
echo "=========================================="