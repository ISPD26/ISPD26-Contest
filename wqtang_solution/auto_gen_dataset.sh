#!/bin/bash

# Check if design name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <design name>"
    echo "Example: $0 aes"
    exit 1
fi

DESIGN_NAME=$1

# Get all non-5-digit folders from design (skip folders that are 5 digits or begin with 5 digits)
FOLDERS=($(ls -d ./training_set/$DESIGN_NAME/*/ | grep -v '/[0-9]\{5\}' | xargs -n1 basename))

# Generate 1000 datasets (05000-05999), each with a new random folder
for i in {05000..05999}; do
    SELECTED="${FOLDERS[$RANDOM % ${#FOLDERS[@]}]}"
    PLACER=("dreamplace" "openroad")
    SELECTED_PLACER="${PLACER[$RANDOM % 2]}"
    echo "Dataset $i using: $SELECTED with $SELECTED_PLACER"
    ./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME $i $i 20 20 $SELECTED_PLACER "$SELECTED"
done

# Original commands
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 00000 00999 20 20 dreamplace
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 01000 01999 20 20 openroad
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 02000 02999 100 0 dreamplace
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 03000 03999 0 100 openroad
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 04000 04499 50 50 openroad
./scripts/gen_training_set.sh ./training_set/$DESIGN_NAME 04499 04999 50 50 dreamplace
