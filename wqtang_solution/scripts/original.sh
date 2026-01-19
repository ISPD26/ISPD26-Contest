#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <design_name> <output path>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$(basename $1)
OUTPUT_PATH=$2
mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$(realpath "$2")

ASAP7_PATH=$(realpath "./testcases/ASAP7")
INPUT_DEF=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.def")
INPUT_SDC=$(realpath "./testcases/${DESIGN_NAME}/${DESIGN_NAME}.sdc")

# Check if optimization was successful
OUTPUT_DEF=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.def")
OUTPUT_CHANGELIST=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.changelist")
if [ $? -eq 0 ]; then
    echo "Original (baseline) processing completed successfully!"
    # Output DEF file should be in results directory
    RESULT_DEF="$INPUT_DEF"
    if [ -f "$RESULT_DEF" ]; then
        # cp $RESULT_DEF "$OUTPUT_DEF"
        ./bin/gen_changelist "${INPUT_DEF}" "${OUTPUT_DEF}" "${OUTPUT_CHANGELIST}"
        echo "Original DEF file: ${OUTPUT_DEF}"
        echo "Original CHANGELIST file: ${OUTPUT_CHANGELIST}"
        ./scripts/eval.sh "${OUTPUT_DEF}" ${INPUT_SDC} ${ASAP7_PATH} ${OUTPUT_PATH}
        
        # Create output directory structure for other scripts
        mkdir -p "./output/${DESIGN_NAME}"
        
        # For original baseline, the score should be 0 as specified in requirements
        echo "Original baseline score: 0"
        echo "S = 0" > "${OUTPUT_PATH}/${DESIGN_NAME}.score"
        
        # Call write_ans.sh to set initial solution baseline
        ./scripts/write_ans.sh "${DESIGN_NAME}" "${INPUT_DEF}" "${OUTPUT_PATH}"
    else
        echo "Error: Original DEF file not found!"
        exit 1
    fi
else
    echo "Error: Original processing failed!"
    exit 1
fi
