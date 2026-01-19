#!/bin/bash

# Usage: ./tar_dataset.sh <design name>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <design name>"
    exit 1
fi

DESIGN_NAME=$1
SOURCE_DIR="training_set/${DESIGN_NAME}"
OUTPUT_FILE="${DESIGN_NAME}_training_set.tar.gz"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Directory ${SOURCE_DIR} does not exist"
    exit 1
fi

# Create tar.gz file with folders 00000 to 05999
echo "Compressing training set for ${DESIGN_NAME}..."
tar -zcvf "$OUTPUT_FILE" -C "$SOURCE_DIR" $(seq -f "%05g" 0 5999)

if [ $? -eq 0 ]; then
    echo "Successfully created ${OUTPUT_FILE}"
else
    echo "Error creating archive"
    exit 1
fi
