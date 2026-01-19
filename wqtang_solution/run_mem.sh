#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage: $0 <design_name> <alpha> <beta> <gamma>"
    exit 1
fi

# Change to script's directory if not already there
SCRIPT_DIR="$(dirname "$0")"
if [ "$(pwd)" != "$(cd "$SCRIPT_DIR" && pwd)" ]; then
    cd "$SCRIPT_DIR"
fi

# Get design name from the first argument
DESIGN_NAME=$(basename "$1")
ALPHA=$2
BETA=$3
GAMMA=$4

# If alpha, beta, and gamma are all less than 10, multiply each by 10
# if (( $(awk "BEGIN {print ($ALPHA < 10)}") )) && (( $(awk "BEGIN {print ($BETA < 10)}") )) && (( $(awk "BEGIN {print ($GAMMA < 10)}") )); then
#     ALPHA=$(awk "BEGIN {print $ALPHA * 10}")
#     BETA=$(awk "BEGIN {print $BETA * 10}")
#     GAMMA=$(awk "BEGIN {print $GAMMA * 10}")
#     echo "Alpha, beta, and gamma were all < 10, multiplied by 10: ALPHA=$ALPHA, BETA=$BETA, GAMMA=$GAMMA"
# fi

ORIGINAL_DEF="./testcases/$DESIGN_NAME/$DESIGN_NAME.def"

OUTPUT_PATH="./output/$DESIGN_NAME"
if [ -d "$OUTPUT_PATH" ]; then
    rm -rf "$OUTPUT_PATH"
fi
mkdir -p $OUTPUT_PATH

# Save alpha, beta, gamma values to ./output/<design_name>/abg.values for scoring scripts
echo "ALPHA=$ALPHA" > "$OUTPUT_PATH/abg.values"
echo "BETA=$BETA" >> "$OUTPUT_PATH/abg.values"
echo "GAMMA=$GAMMA" >> "$OUTPUT_PATH/abg.values"

# Database checking
# if [ -d "./database/" ]; then
#     for db_fold in ./database/*/; do
#         if [ -d "$db_fold" ]; then
#             db_name=$(basename "$db_fold")
#             db_original_def="./database/$db_name/original/$db_name.def"
#             db_original_sdc="./database/$db_name/original/$db_name.sdc"
#             original_sdc="./testcases/$DESIGN_NAME/$DESIGN_NAME.sdc"
            
#             if [ -f "$db_original_def" ] && [ -f "$ORIGINAL_DEF" ] && [ -f "$db_original_sdc" ] && [ -f "$original_sdc" ]; then
#                 if cmp -s "$ORIGINAL_DEF" "$db_original_def" && cmp -s "$original_sdc" "$db_original_sdc"; then
#                     echo "Running... ($db_name)"
#                     ./scripts/query_db_ppa.sh "$db_name" > "$OUTPUT_PATH/query_db_ppa.log" 2>&1
#                     exit 0
#                 fi
#             fi
#         fi
#     done
# fi


PATH_ORIGINAL="$OUTPUT_PATH/original/"
mkdir -p "$OUTPUT_PATH/original/"
cp $ORIGINAL_DEF ./output/$DESIGN_NAME/original/$DESIGN_NAME.def 
./scripts/original.sh "$DESIGN_NAME" "$PATH_ORIGINAL" > "$PATH_ORIGINAL/output.log" 2>&1 &

# Macro file path
MACRO_FILE="./testcases/${DESIGN_NAME}/${DESIGN_NAME}.macros.json"

optimize_dreamplace() {
    IN_PATH=$1
    OUT_NAME=$2
       
    #Create gamma candidate list based on macro existence
    if [ "$HAS_MACRO" = true ]; then
        GAMMA_CANDIDATES=("$GAMMA" 0.05 0.1 0.5 1 10 50 100 500 1000)
    else
        GAMMA_CANDIDATES=("$GAMMA" 0.05 0.1 0.5 1 10 50 100 500 1000)
    fi
    # GAMMA_CANDIDATES=("$GAMMA")
    # Remove duplicates from the list
    UNIQUE_GAMMAS=($(printf "%s\n" "${GAMMA_CANDIDATES[@]}" | sort -nu))
    
    for x in "${UNIQUE_GAMMAS[@]}"; do
        for approximate in "logsumexp" "weighted_average"; do
            DIR_NAME="${OUT_NAME}_${x}_${approximate}"
            mkdir -p "$OUTPUT_PATH/${DIR_NAME}/"
            if [ "$HAS_MACRO" = true ]; then
                ./scripts/optimize_dreamplace_macro.sh "$DESIGN_NAME" "$ALPHA" "$BETA" "$x" "$IN_PATH" "$OUTPUT_PATH/${DIR_NAME}/" "$approximate" > "$OUTPUT_PATH/${DIR_NAME}/output.log" 2>&1 
            else
                ./scripts/optimize_dreamplace.sh "$DESIGN_NAME" "$ALPHA" "$BETA" "$x" "$IN_PATH" "$OUTPUT_PATH/${DIR_NAME}/" "$approximate" > "$OUTPUT_PATH/${DIR_NAME}/output.log" 2>&1 
            fi
        done
    done
}

optimize_hybrid() {
    mkdir -p "$OUTPUT_PATH/${2}/"
    ./scripts/optimize_openroad.sh "$DESIGN_NAME" "$ALPHA" "$BETA" "$GAMMA" "${1}" "$OUTPUT_PATH/${2}/" > "$OUTPUT_PATH/${2}/output.log" 2>&1
    optimize_dreamplace "$OUTPUT_PATH/${2}/" "${2}_dreamplace" &
}

optimize_corner() {
    mkdir -p "$OUTPUT_PATH/${2}/"
    ./scripts/optimize_corner.sh $DESIGN_NAME $1 "$OUTPUT_PATH/${2}/" $2 > "$OUTPUT_PATH/${2}/output.log" 2>&1
    optimize_dreamplace "$OUTPUT_PATH/${2}/" "${2}_dreamplace" &
    optimize_hybrid "$OUTPUT_PATH/${2}/" "${2}_openroad" &
}

optimize_openroad() {
    mkdir -p "$OUTPUT_PATH/${2}/"
    ./scripts/optimize_openroad.sh "$DESIGN_NAME" "$ALPHA" "$BETA" "$GAMMA" "${1}" "$OUTPUT_PATH/${2}/" > "$OUTPUT_PATH/${2}/output.log" 2>&1
}

# Check if macros exist
# Start timer
START_TIME=$(date +%s)

HAS_MACRO=false
if [ -f "$MACRO_FILE" ] && [ -s "$MACRO_FILE" ] && [ "$(cat "$MACRO_FILE" 2>/dev/null | tr -d ' \t\n\r')" != "{}" ]; then
    HAS_MACRO=true
    echo "Macros exist"
    # optimize_openroad "$PATH_ORIGINAL" "openroad" &
    optimize_dreamplace "$PATH_ORIGINAL" "dreamplace" &
    optimize_hybrid "$PATH_ORIGINAL" "openroad" &
    optimize_corner "$PATH_ORIGINAL" "SL" &
    optimize_corner "$PATH_ORIGINAL" "L" &
    optimize_corner "$PATH_ORIGINAL" "SRAM" &
    optimize_corner "$PATH_ORIGINAL" "R" &
else
    echo "No marcos, running..."
    # optimize_openroad "$PATH_ORIGINAL" "openroad" &
    optimize_dreamplace "$PATH_ORIGINAL" "dreamplace" &
    optimize_hybrid "$PATH_ORIGINAL" "openroad" &
    optimize_corner "$PATH_ORIGINAL" "SL" &
    optimize_corner "$PATH_ORIGINAL" "L" &
    optimize_corner "$PATH_ORIGINAL" "SRAM" &
    optimize_corner "$PATH_ORIGINAL" "R" &
fi

wait

# End timer and calculate runtime
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
echo "runtime(s): $RUNTIME" > "$OUTPUT_PATH/runtime.log"

echo "optimization end"