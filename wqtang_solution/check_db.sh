#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    echo "Example: $0 ./database/"
    exit 1
fi

DATABASE_PATH="$1"

if [ ! -d "$DATABASE_PATH" ]; then
    echo "Error: Directory '$DATABASE_PATH' does not exist"
    exit 1
fi

echo "Checking database folders in: $DATABASE_PATH"
echo "----------------------------------------"

for case_dir in "$DATABASE_PATH"/*; do
    if [ -d "$case_dir" ]; then
        case_name=$(basename "$case_dir")
        
        for fold in "$case_dir"/*; do
            if [ -d "$fold" ]; then
                fold_path="$fold"
                fold_name=$(basename "$fold")
                
                # Check for required files
                missing_files=()
                
                if ! ls "$fold"/*.def >/dev/null 2>&1; then
                    missing_files+=("*.def")
                fi
                
                if ! ls "$fold"/*.changelist >/dev/null 2>&1; then
                    missing_files+=("*.changelist")
                fi
                
                if [ ! -f "$fold/PPAD.out" ]; then
                    missing_files+=("PPAD.out")
                fi
                
                # Print warning if files are missing
                if [ ${#missing_files[@]} -gt 0 ]; then
                    echo "WARNING: $fold_path"
                    echo "  Missing files: ${missing_files[*]}"
                fi
            fi
        done
    fi
done

echo "----------------------------------------"
echo "Database check completed"