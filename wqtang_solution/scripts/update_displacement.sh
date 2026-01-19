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

# Check if calc_displacement binary exists
if [ ! -f "./bin/calc_displacement" ]; then
    echo "Error: ./bin/calc_displacement not found!"
    exit 1
fi

echo "=========================================="
echo "Updating displacement for all solutions"
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
        PPAD_FILE="${fold}/PPAD.out"
        
        echo "Processing folder: $FOLD_NAME"
        
        # Check if revised DEF file exists
        if [ ! -f "$REVISED_DEF" ]; then
            echo "  Warning: $REVISED_DEF not found, skipping"
            continue
        fi
        
        # Check if PPAD.out exists
        if [ ! -f "$PPAD_FILE" ]; then
            echo "  Warning: $PPAD_FILE not found, skipping"
            continue
        fi
        
        # Calculate displacement
        echo "  Calculating displacement..."
        DISPLACEMENT_LOG="${fold}/displacement.log"
        ./bin/calc_displacement "$ORIGINAL_DEF" "$REVISED_DEF" 2>&1 | tee "$DISPLACEMENT_LOG" > /dev/null
        
        # Extract average displacement
        AVG_DISPLACEMENT=$(grep "Average displacement per cell:" "$DISPLACEMENT_LOG" | awk '{print $6}')
        if [ -z "$AVG_DISPLACEMENT" ]; then
            echo "  Warning: Could not extract displacement, skipping"
            continue
        fi
        
        echo "  New displacement: $AVG_DISPLACEMENT"
        
        # Read existing PPAD.out and update line 4
        if [ -f "$PPAD_FILE" ]; then
            # Extract previous displacement value from line 4
            PREVIOUS_DISPLACEMENT=$(sed -n '4p' "$PPAD_FILE" | sed 's/Displacement: //')
            
            # Create temporary file
            TEMP_FILE="${fold}/PPAD.out.tmp"
            
            # Read the file line by line and update line 4
            LINE_NUM=0
            while IFS= read -r line || [ -n "$line" ]; do
                LINE_NUM=$((LINE_NUM + 1))
                if [ $LINE_NUM -eq 4 ]; then
                    echo "Displacement: $AVG_DISPLACEMENT" >> "$TEMP_FILE"
                else
                    echo "$line" >> "$TEMP_FILE"
                fi
            done < "$PPAD_FILE"
            
            # Replace original file with updated version
            mv "$TEMP_FILE" "$PPAD_FILE"
            
            # Compare and display displacement change
            if [ "$PREVIOUS_DISPLACEMENT" = "$AVG_DISPLACEMENT" ]; then
                echo "  The displacement is same"
            else
                echo "  Updated displacement: $PREVIOUS_DISPLACEMENT -> $AVG_DISPLACEMENT"
            fi
        fi
        
        
        PROCESSED=$((PROCESSED + 1))
        echo "  Progress: $PROCESSED/$TOTAL completed"
        echo
    fi
done

echo "=========================================="
echo "Displacement update completed!"
echo "Processed $PROCESSED solution folders"
echo "=========================================="