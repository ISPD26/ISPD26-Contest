#!/bin/bash

# Get all non-5-digit folders from aes (skip folders that are 5 digits or begin with 5 digits)
# FOLDERS=($(ls -d ./training_set/aes/*/ | grep -v '/[0-9]\{5\}' | xargs -n1 basename))

# # Generate 1000 datasets (05000-05999), each with a new random folder
# for i in {05000..05999}; do
#     SELECTED="${FOLDERS[$RANDOM % ${#FOLDERS[@]}]}"
#     echo "Dataset $i using: $SELECTED"
#     ./scripts/gen_training_set.sh ./training_set/aes $i $i 20 20 dreamplace "$SELECTED"
# done

# Original commands
./scripts/gen_training_set.sh ./training_set/aes 00000 00999 20 20 dreamplace
./scripts/gen_training_set.sh ./training_set/aes 01000 01999 20 20 openroad
./scripts/gen_training_set.sh ./training_set/aes 02000 02999 100 0 dreamplace
./scripts/gen_training_set.sh ./training_set/aes 03000 03999 0 100 openroad
./scripts/gen_training_set.sh ./training_set/aes 04000 04499 50 50 openroad
./scripts/gen_training_set.sh ./training_set/aes 04499 04999 50 50 dreamplace
