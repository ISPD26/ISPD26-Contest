#!/bin/bash

# Script to package selected files to cadc-yyyymmdd_mmss.tar.gz with SB_Place/ directory structure
# Usage: ./tar.sh

# Generate filename with current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M")

OUTPUT_FILE="cadc-${TIMESTAMP}.tar.gz"

echo "Creating $OUTPUT_FILE..."

# Create tar.gz with solution/ as root directory, include only selected files/folders
tar -czf "$OUTPUT_FILE" \
    --transform 's,^,solution/,' \
    --exclude='extpkgs/DREAMPlace/build' \
    extpkgs/DREAMPlace scripts src database\
    *.sh makefile README.md\
    extpkgs/*.deb 

if [ $? -eq 0 ]; then
    echo "Successfully created $OUTPUT_FILE"
    echo "File size: $(du -h $OUTPUT_FILE | cut -f1)"
else
    echo "Error: Failed to create archive"
    exit 1
fi