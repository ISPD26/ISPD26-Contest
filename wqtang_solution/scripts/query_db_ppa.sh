#!/bin/bash

# query_db_ppa.sh - Query database and run write_ans_ppa.sh for all folds
# Usage: scripts/query_db_ppa.sh <design_name>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <design_name>"
    exit 1
fi

DESIGN_NAME=$1

# Check if database directory exists
DATABASE_DIR="./database/${DESIGN_NAME}"
if [ ! -d "$DATABASE_DIR" ]; then
    echo "Error: Database directory $DATABASE_DIR not found"
    exit 1
fi

# Check if original directory and DEF file exist
ORIGINAL_DEF="${DATABASE_DIR}/original/${DESIGN_NAME}.def"
if [ ! -f "$ORIGINAL_DEF" ]; then
    echo "Error: Original DEF file $ORIGINAL_DEF not found"
    exit 1
fi

echo "Querying database for design: $DESIGN_NAME (PPA metrics only)"

# Traverse all directories in database/<design_name>/ except 'original'
for fold_dir in "${DATABASE_DIR}"/*; do
    if [ -d "$fold_dir" ]; then
        fold_name=$(basename "$fold_dir")

        echo "Processing : $fold_dir"

        # Run write_ans_ppa.sh for this fold
        ./scripts/write_ans_ppa.sh "$DESIGN_NAME" "$ORIGINAL_DEF" "$fold_dir"

        echo ""

    fi
done
