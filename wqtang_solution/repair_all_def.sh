#!/bin/bash

# Usage: ./repair_all_def.sh <path>
# For each folder x in <path>, run scripts/repair_def.py x.def x.new.def,
# if the x.new.def is same as the x.def, remove it and print they are same,
# or print updated, and mv x.new.def to x.def

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

path="$1"

if [ ! -d "$path" ]; then
    echo "Error: Directory '$path' does not exist"
    exit 1
fi

# Loop through each directory in the given path
for folder in "$path"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")
        design_name=$(basename "$path")
        def_file="$folder/$design_name.def"
        new_def_file="$folder/$design_name.new.def"
        
        # Check if the .def file exists
        if [ -f "$def_file" ]; then
            echo "Processing $folder_name..."
            
            # Run repair_def.py
            if python3 scripts/repair_def.py "$def_file" "$new_def_file"; then
                # Compare the files
                if cmp -s "$def_file" "$new_def_file"; then
                    # Files are the same, remove the new file
                    rm "$new_def_file"
                    echo "$folder_name: they are same"
                else
                    # Files are different, replace the original
                    mv "$new_def_file" "$def_file"
                    echo "$folder_name: updated"
                fi
            else
                echo "$folder_name: error running repair_def.py"
            fi
        else
            echo "$design_name: $design_name.def not found"
        fi
    fi
done