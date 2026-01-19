#!/bin/bash

# Usage: ./scripts/repair_ppa.sh <design_path>
# Example: ./scripts/repair_ppa.sh ./designs/ariane

# Check if design path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <design_path>"
    echo "Example: $0 ./designs/ariane"
    exit 1
fi

DESIGN_PATH=$1

# Check if design path exists
if [ ! -d "$DESIGN_PATH" ]; then
    echo "Error: Design path '$DESIGN_PATH' does not exist"
    exit 1
fi

# Iterate over subdirectories in the design path
for fold in "$DESIGN_PATH"/*; do
    # Skip if not a directory
    if [ ! -d "$fold" ]; then
        continue
    fi

    # Skip the 'original' directory if it exists
    if [ "$(basename "$fold")" = "original" ]; then
        continue
    fi

    # Get folder name
    folder_name=$(basename "$fold")

    echo "Processing folder: $folder_name"

    # Call eval.sh for each folder
    # Arguments: <def_file> <sdc_file> <lib_path> <output_path>
    ./scripts/eval.sh \
        "$fold/ariane.def" \
        "$DESIGN_PATH/original/ariane.sdc" \
        "./testcases/ASAP7/" \
        "$fold/"
done

echo "All folders processed"
