#!/bin/bash

# Check if all arguments are provided
if [ $# -lt 6 ] || [ $# -gt 7 ]; then
    echo "Usage: $0 <path> <from> <to> <replace_per> <move_per> <legalization method> <original fold>"
    echo "Example: $0 training_set/aes 00000 05000 20 20 dreamplace"
    echo "Example: $0 training_set/aes 00000 05000 20 20 dreamplace custom_original"
    echo "Note: If <original fold> is empty, 'original' will be used by default"
    exit 1
fi

PATH_ARG=$1
FROM=$2
TO=$3
REPLACE_PER=$4
MOVE_PER=$5
LEGALIZE_METHOD=$6
ORIGINAL_FOLD=${7:-original}  # Use 'original' as default if not provided

# Check if path exists
if [ ! -d "$PATH_ARG" ]; then
    echo "Error: Directory $PATH_ARG not found!"
    exit 1
fi

# Check if original folder exists
ORIGINAL_PATH="$PATH_ARG/$ORIGINAL_FOLD"
if [ ! -d "$ORIGINAL_PATH" ]; then
    echo "Error: Original directory $ORIGINAL_PATH not found!"
    exit 1
fi

DESIGN_NAME=$(basename "$PATH_ARG")
echo "Design name: $DESIGN_NAME"
echo "Original folder: $ORIGINAL_FOLD"
echo "Generating datasets from $FROM to $TO"
echo "Replace percentage: $REPLACE_PER%, Move percentage: $MOVE_PER%"
echo "Legalization method: $LEGALIZE_METHOD"

# Get the absolute paths
ASAP7_PATH=$(realpath "./testcases/ASAP7")
ORIGINAL_DEF=$(realpath "$ORIGINAL_PATH/$DESIGN_NAME.def")
ORIGINAL_SDC=$(realpath "$ORIGINAL_PATH/$DESIGN_NAME.sdc")

# Check if original files exist
if [ ! -f "$ORIGINAL_DEF" ]; then
    echo "Error: Original DEF file not found: $ORIGINAL_DEF"
    exit 1
fi

if [ ! -f "$ORIGINAL_SDC" ]; then
    echo "Error: Original SDC file not found: $ORIGINAL_SDC"
    exit 1
fi

echo "=========================================="
echo "Generating training datasets"
echo "=========================================="

SUCCESSFUL=0
FAILED=0

# Convert FROM and TO to integers for iteration
FROM_INT=$((10#$FROM))
TO_INT=$((10#$TO))
TOTAL_DATASETS=$((TO_INT - FROM_INT + 1))

for i in $(seq $FROM_INT $TO_INT); do
    # Use 5-digit zero-padded folder name
    FOLDER_NAME=$(printf "%05d" $i)

    echo ""
    echo "[$((i - FROM_INT + 1))/$TOTAL_DATASETS] Generating dataset $FOLDER_NAME..."

    # Create dataset folder
    DATASET_FOLDER="$PATH_ARG/$FOLDER_NAME"
    mkdir -p "$DATASET_FOLDER"

    # Generate modified DEF file
    MAX_RETRIES=3
    LEGALIZE_SUCCESS=0

    for retry in $(seq 1 $MAX_RETRIES); do
        echo "  Attempt $retry: Generating modified DEF (replace=${REPLACE_PER}%, move=${MOVE_PER}%)..."
        TEMP_DEF="$DATASET_FOLDER/temp_${DESIGN_NAME}.def"

        python3 ./scripts/gen_def.py "$ORIGINAL_DEF" "$TEMP_DEF" $REPLACE_PER $MOVE_PER > /dev/null 2>&1

        if [ $? -ne 0 ]; then
            echo "  Error: Failed to generate DEF file!"
            continue
        fi

        # Copy SDC file
        echo "  Copying SDC file..."
        cp "$ORIGINAL_SDC" "$DATASET_FOLDER/$DESIGN_NAME.sdc"

        # Generate .v file using write_v_2.sh
        echo "  Generating .v file..."
        ./scripts/write_v_2.sh "$TEMP_DEF" "$DATASET_FOLDER/$DESIGN_NAME.sdc" "$DATASET_FOLDER/$DESIGN_NAME.v" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "  Error: Failed to generate .v file!"
            rm -f "$TEMP_DEF"
            continue
        fi

        # Legalize the DEF using specified method
        echo "  Legalizing DEF file with ${LEGALIZE_METHOD}..."
        if [ "$LEGALIZE_METHOD" = "dreamplace" ]; then
            ./scripts/legalize_dreamplace.sh "$TEMP_DEF" "$DATASET_FOLDER/$DESIGN_NAME.v" "$DATASET_FOLDER/$DESIGN_NAME.sdc" "$DATASET_FOLDER/$DESIGN_NAME.def" > "$DATASET_FOLDER/legalize.log" 2>&1
        elif [ "$LEGALIZE_METHOD" = "openroad" ]; then
            ./scripts/legalize_openroad.sh "$TEMP_DEF" "$DATASET_FOLDER/$DESIGN_NAME.v" "$DATASET_FOLDER/$DESIGN_NAME.sdc" "$DATASET_FOLDER/$DESIGN_NAME.def" > "$DATASET_FOLDER/legalize.log" 2>&1
        else
            echo "  Error: Invalid legalization method '$LEGALIZE_METHOD'. Use 'dreamplace' or 'openroad'."
            rm -f "$TEMP_DEF"
            continue
        fi

        if [ $? -eq 0 ] && [ -f "$DATASET_FOLDER/$DESIGN_NAME.def" ]; then
            echo "  ✓ Legalization successful!"
            LEGALIZE_SUCCESS=1
            # Remove temp DEF and log on success
            rm -f "$TEMP_DEF" "$DATASET_FOLDER/legalize.log"
            break
        else
            echo "  ⊗ Legalization failed (log saved), retrying..."
            # Clean up for retry
            rm -f "$TEMP_DEF" "$DATASET_FOLDER/$DESIGN_NAME.def" "$DATASET_FOLDER/$DESIGN_NAME.v"
        fi
    done

    if [ $LEGALIZE_SUCCESS -eq 0 ]; then
        echo "  ✗ Failed to legalize after $MAX_RETRIES attempts"
        # Rename failed folder
        FAILED_FOLDER="${PATH_ARG}/${FOLDER_NAME}_failed"
        mv "$DATASET_FOLDER" "$FAILED_FOLDER"
        echo "  Renamed folder to ${FOLDER_NAME}_failed"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Generate PPA.out using eval_tiny.sh
    echo "  Generating PPA.out..."
    DEF_FILE="$DATASET_FOLDER/$DESIGN_NAME.def"
    SDC_FILE="$DATASET_FOLDER/$DESIGN_NAME.sdc"

    ./scripts/eval_tiny.sh "$DEF_FILE" "$SDC_FILE" "$ASAP7_PATH" "$DATASET_FOLDER" > /dev/null 2>&1

    if [ $? -ne 0 ] || [ ! -f "$DATASET_FOLDER/PPA.out" ]; then
        echo "  ✗ Failed to generate PPA.out"
        # Rename failed folder
        FAILED_FOLDER="${PATH_ARG}/${FOLDER_NAME}_failed"
        mv "$DATASET_FOLDER" "$FAILED_FOLDER"
        echo "  Renamed folder to ${FOLDER_NAME}_failed"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Clean up .tcl and .log files on success
    echo "  Cleaning up temporary files..."
    rm -f "$DATASET_FOLDER"/*.tcl "$DATASET_FOLDER"/*.log "$DATASET_FOLDER"/*.json

    echo "  ✓ Successfully generated dataset $FOLDER_NAME"
    SUCCESSFUL=$((SUCCESSFUL + 1))
done

echo ""
echo "=========================================="
echo "Generation complete!"
echo "Successful: $SUCCESSFUL/$TOTAL_DATASETS"
echo "Failed: $FAILED/$TOTAL_DATASETS"
echo "=========================================="

if [ $SUCCESSFUL -gt 0 ]; then
    exit 0
else
    exit 1
fi
