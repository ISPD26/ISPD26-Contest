#!/usr/bin/env bash
# optimize_openroad_slew.sh - Run OpenROAD optimization with slew margin
# Usage: optimize_openroad_slew.sh <DESIGN_DIR> <TECH_DIR> <OUTPUT_DIR> <DESIGN_NAME> <INPUT_PATH> <SLEW_MARGIN>

#######################################
# Default settings
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(dirname "$SCRIPT_DIR")"
TCL_DIR="$SOLUTION_DIR/tcl"

cd "$SOLUTION_DIR" || exit 1
#######################################
# Usage
#######################################
usage() {
  echo "Usage:"
  echo "  $0 <DESIGN_DIR> <TECH_DIR> <OUTPUT_DIR> <DESIGN_NAME>"
  echo
  echo "Arguments:"
  echo "  DESIGN_DIR   - Path to benchmark design folder"
  echo "  TECH_DIR     - Path to technology files"
  echo "  OUTPUT_DIR   - Path to output directory"
  echo "  DESIGN_NAME  - Name of the design"
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

#######################################
# Template and derived paths
#######################################
TEMPLATE_FILE="${TCL_DIR}/baseline.tcl"
TCL_NAME="baseline"

#######################################
# Sanity checks
#######################################
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: Template file not found: $TEMPLATE_FILE" >&2
  exit 2
fi

#######################################
# Prepare temporary TCL directory
#######################################
TEMP_TCL_DIR="${OUTPUT_DIR}/temp/${DESIGN_NAME}/${TCL_NAME}"
mkdir -p "$TEMP_TCL_DIR"

GENERATED_TCL_FILE="${TEMP_TCL_DIR}/${TCL_NAME}.tcl"

#######################################
# Generate TCL file from template
# 1. Replace environment variable references with actual values
# 2. Add -slew_margin to repair_design
# 3. Use INPUT_PATH for reading def/v files
#######################################
echo "Generating TCL file: $GENERATED_TCL_FILE"

# First, replace env vars and modify repair_design to add slew_margin
sed -e "s|\$::env(DESIGN_NAME)|\"${DESIGN_NAME}\"|g" \
    -e "s|\$::env(TECH_DIR)|\"${TECH_DIR}\"|g" \
    -e "s|\$::env(DESIGN_DIR)|\"${DESIGN_DIR}\"|g" \
    -e "s|\$::env(OUTPUT_DIR)|\"${OUTPUT_DIR}\"|g" \
    -e "s|\$design_dir/contest.v|\$design_dir/\$design_name.v|g" \
    -e "s|\$design_dir/contest.def|\$design_dir/\$design_name.def|g" \
    -e "s|\$design_dir/contest.sdc|\"${SOLUTION_DIR}/output_temp/${DESIGN_NAME}/contest.sdc\"|g" \
    "$TEMPLATE_FILE" > "$GENERATED_TCL_FILE"

if [[ ! -f "$GENERATED_TCL_FILE" ]]; then
  echo "Error: Failed to generate TCL file: $GENERATED_TCL_FILE" >&2
  exit 4
fi

#######################################
# Prepare output directory
#######################################
mkdir -p "$OUTPUT_DIR"

#######################################
# Run OpenROAD
#######################################
echo "Running OpenROAD with generated baseline TCL script..."
openroad \
  -no_init \
  -exit \
  "$GENERATED_TCL_FILE"


./scripts/eval.sh "$DESIGN_DIR" "$TECH_DIR" "$OUTPUT_DIR" "$DESIGN_NAME"

echo "Baseline optimization completed"
