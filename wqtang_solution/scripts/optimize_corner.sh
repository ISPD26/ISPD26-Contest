#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <design_name> <input path> <output path> <corner>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$(basename $1)
INPUT_PATH=$(realpath "$2")
OUTPUT_PATH=$3
mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$(realpath "$3")

ASAP7_PATH=$(realpath "./testcases/ASAP7")
INPUT_DEF=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.def")
INPUT_VERILOG=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.v")
INPUT_SDC=$(realpath "./testcases/${DESIGN_NAME}/${DESIGN_NAME}.sdc")

./bin/change_corner "$INPUT_DEF" "$OUTPUT_PATH/${DESIGN_NAME}.def" "$4"

# Check if optimization was successful
OUTPUT_DEF=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.def")
OUTPUT_CHANGELIST=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.changelist")
if [ $? -eq 0 ]; then
    echo "Optimization completed successfully!"
    # Output DEF file should be in results directory
    if [ -f "$OUTPUT_DEF" ]; then
        OUTPUT_PARENT_PATH=$(dirname $OUTPUT_PATH)
        ORIGINAL_DEF="${OUTPUT_PARENT_PATH}/original/${DESIGN_NAME}.def"

        ./bin/gen_changelist "${ORIGINAL_DEF}" "${OUTPUT_DEF}" "${OUTPUT_CHANGELIST}"
        echo "Optimized DEF file: ${OUTPUT_DEF}"
        echo "Optimized CHANGELIST file: ${OUTPUT_CHANGELIST}"
        ./scripts/eval.sh "${OUTPUT_DEF}" ${INPUT_SDC} ${ASAP7_PATH} ${OUTPUT_PATH}
        
        # Call write_ans.sh to handle scoring and solution updates
        ./scripts/write_ans.sh "${DESIGN_NAME}" "${ORIGINAL_DEF}" "${OUTPUT_PATH}"
    else
        echo "Error: Optimized DEF file not found!"
        exit 1
    fi
else
    echo "Error: corner optimization failed!"
    exit 1
fi
