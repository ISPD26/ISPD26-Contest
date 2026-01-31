#!/usr/bin/env bash
# set -euo pipefail

#######################################
# Default settings
#######################################
TCL_NAME="baseline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TCL_DIR="$SCRIPT_DIR/tcl"
BIN_DIR="$SCRIPT_DIR/bin"


cd $SCRIPT_DIR
#######################################
# Usage
#######################################
usage() {
  echo "Usage:"
  echo "  $0 <DESIGN_DIR> <TECH_DIR> <OUTPUT_DIR> <DESIGN_NAME>"
  exit 1
}

#######################################
# Check required arguments
#######################################
if [[ $# -lt 4 ]]; then
  usage
fi

#######################################
# Required positional arguments
#######################################
DESIGN_DIR="$1"
TECH_DIR="$2"
OUTPUT_DIR="$3"
DESIGN_NAME="$4"

shift 4

#######################################
# 1.1 output original design
#######################################
PATH_OUTPUT_TEMP_DIR="./output_temp/${DESIGN_NAME}"
mkdir -p "$PATH_OUTPUT_TEMP_DIR"

PATH_ORIGINAL="$PATH_OUTPUT_TEMP_DIR/original"
mkdir -p "$PATH_ORIGINAL"

ORIGINAL_SDC="$DESIGN_DIR/contest.sdc"
ORIGINAL_DEF="$DESIGN_DIR/contest.def"
ORIGINAL_VERILOG="$DESIGN_DIR/contest.v"

cp "$ORIGINAL_DEF" "$PATH_ORIGINAL/$DESIGN_NAME.def"
cp "$ORIGINAL_VERILOG" "$PATH_ORIGINAL/$DESIGN_NAME.v"

# Copy the original SDC file to the temporary output directory
# other optimization scripts may need it 
cp "$ORIGINAL_SDC" "$PATH_OUTPUT_TEMP_DIR/contest.sdc"

# generate original evaluation and ans files
# ./scripts/eval.sh "$DESIGN_DIR" "$TECH_DIR" "$PATH_ORIGINAL" "$DESIGN_NAME" > "$PATH_ORIGINAL/output.log" 2>&1

# write file to output if its score is better than the best one in output dir
# ./scripts/write_ans.sh "$DESIGN_NAME" "$PATH_ORIGINAL" "$OUTPUT_DIR" >> "$PATH_ORIGINAL/output.log" 2>&1

#######################################
# 1.2 optimization functions definition
#######################################


optimize_baseline() {
    local INPUT_PATH="${1}"
    local OPT_NAME="${2}"
    local OPT_OUTPUT_PATH="$PATH_OUTPUT_TEMP_DIR/${OPT_NAME}"
    mkdir -p "$OPT_OUTPUT_PATH/"
    
    ./scripts/optimize_openroad_baseline.sh "$INPUT_PATH" "$TECH_DIR" "$OPT_OUTPUT_PATH" "$DESIGN_NAME" "${INPUT_PATH}" > "$OPT_OUTPUT_PATH/output.log" 2>&1
    ./scripts/write_ans.sh "$DESIGN_NAME" "$OPT_OUTPUT_PATH" "$OUTPUT_DIR" >> "$OPT_OUTPUT_PATH/output.log" 2>&1
}

optimize_openroad_slew() {
    # local INPUT_PATH="${1}"
    local OPT_NAME="${2}"
    local SLEW_MARGIN="${3}"
    local OPT_OUTPUT_PATH="$PATH_OUTPUT_TEMP_DIR/${OPT_NAME}_SLEW_MARGIN_${SLEW_MARGIN}"
    mkdir -p "$OPT_OUTPUT_PATH/"
    
    ./scripts/optimize_openroad_slew.sh "$DESIGN_DIR" "$TECH_DIR" "$OPT_OUTPUT_PATH" "$DESIGN_NAME" "${INPUT_PATH}" "${SLEW_MARGIN}" > "$OPT_OUTPUT_PATH/output.log" 2>&1
    ./scripts/write_ans.sh "$DESIGN_NAME" "$OPT_OUTPUT_PATH" "$OUTPUT_DIR" >> "$OPT_OUTPUT_PATH/output.log" 2>&1
}


change_corner_opt() {
    local INPUT_PATH="${1}"
    local CORNER_NAME="${2}"
    mkdir -p "${INPUT_PATH}_${CORNER_NAME}"
    ./bin/change_corner "$DESIGN_DIR/contest.def" "${INPUT_PATH}_${CORNER_NAME}/$DESIGN_NAME.def" \
                        "$DESIGN_DIR/contest.v" "${INPUT_PATH}_${CORNER_NAME}/$DESIGN_NAME.v" "$CORNER_NAME" > /dev/null 2>&1
    optimize_baseline "${INPUT_PATH}_${CORNER_NAME}" "baseline_${CORNER_NAME}"
}


#######################################
# 1.3 run optimization functions
#######################################

START_TIME=$(date +%s)
# run different optimization strategies in parallel.

# Known designs that can run in parallel
KNOWN_DESIGNS="aes_cipher_top aes_cipher_top_v2 ariane ariane_v2  jpeg_encoder jpeg_encoder_v2 ariane_h1 ariane_h2 "
# the design cannot run in parallel: bsg_chip bsg_chip_v2 bsg_chip_h1 bsg_chip_h2


is_known_design() {
    local design="$1"
    for known in $KNOWN_DESIGNS; do
        if [[ "$design" == "$known" ]]; then
            return 0
        fi
    done
    return 1
}

if is_known_design "$DESIGN_NAME"; then
    # Run in parallel for known designs
    optimize_baseline "$PATH_ORIGINAL" "baseline" &
    change_corner_opt "$PATH_ORIGINAL" "SL" &
    change_corner_opt "$PATH_ORIGINAL" "L" &
    change_corner_opt "$PATH_ORIGINAL" "R" &
else
    # Run sequentially for unknown designs
    # optimize_baseline "$PATH_ORIGINAL" "baseline"
    # change_corner_opt "$PATH_ORIGINAL" "SL"
    # change_corner_opt "$PATH_ORIGINAL" "L"
    # change_corner_opt "$PATH_ORIGINAL" "R"

    # Run at most two jobs in parallel to avoid OOM
    change_corner_opt "$PATH_ORIGINAL" "L" &
    change_corner_opt "$PATH_ORIGINAL" "R" &
    wait -n
    optimize_baseline "$PATH_ORIGINAL" "baseline" &
    wait -n
    change_corner_opt "$PATH_ORIGINAL" "SL" &

fi

# optimize_openroad_slew "$PATH_ORIGINAL" "openroad_slew" 20 &
# optimize_openroad_slew "$PATH_ORIGINAL" "openroad_slew" 30 &


# wait for all background processes to finish
wait
# End timer and calculate runtime
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
echo "runtime(s): $RUNTIME" > "$PATH_OUTPUT_TEMP_DIR/runtime.log"

echo "optimization end"