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

ORIGINAL_DEF="$DESIGN_DIR/contest.def"
ORIGINAL_VERILOG="$DESIGN_DIR/contest.v"

cp "$ORIGINAL_DEF" "$PATH_ORIGINAL/$DESIGN_NAME.def"
cp "$ORIGINAL_VERILOG" "$PATH_ORIGINAL/$DESIGN_NAME.v"

# generate original evaluation and ans files
./scripts/eval.sh "$DESIGN_DIR" "$TECH_DIR" "$PATH_ORIGINAL" "$DESIGN_NAME" > "$PATH_ORIGINAL/output.log" 2>&1

# write file to output if its score is better than the best one in output dir
./scripts/write_ans.sh "$DESIGN_NAME" "$PATH_ORIGINAL" "$OUTPUT_DIR" >> "$PATH_ORIGINAL/output.log" 2>&1

#######################################
# 1.2 optimization functions definition
#######################################


optimize_baseline() {
    # local INPUT_PATH="${1}"
    local OPT_NAME="${2}"
    local OPT_OUTPUT_PATH="$PATH_OUTPUT_TEMP_DIR/${OPT_NAME}"
    mkdir -p "$OPT_OUTPUT_PATH/"
    
    ./scripts/optimize_openroad_baseline.sh "$DESIGN_DIR" "$TECH_DIR" "$OPT_OUTPUT_PATH" "$DESIGN_NAME" "${INPUT_PATH}" > "$OPT_OUTPUT_PATH/output.log" 2>&1
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




#######################################
# 1.3 run optimization functions
#######################################

START_TIME=$(date +%s)
# run different optimization strategies in parallel.
optimize_baseline "$PATH_ORIGINAL" "baseline" &
optimize_openroad_slew "$PATH_ORIGINAL" "openroad_slew" 20 &
optimize_openroad_slew "$PATH_ORIGINAL" "openroad_slew" 30 &


# wait for all background processes to finish
wait
# End timer and calculate runtime
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
echo "runtime(s): $RUNTIME" > "$PATH_OUTPUT_TEMP_DIR/runtime.log"

echo "optimization end"