#!/usr/bin/env bash
# set -euo pipefail

#######################################
# Default settings
#######################################
TCL_NAME="baseline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TCL_DIR="$SCRIPT_DIR/tcl"

#######################################
# Usage
#######################################
usage() {
  echo "Usage:"
  echo "  $0 <DESIGN_NAME> <TECH_DIR> <DESIGN_DIR> <OUTPUT_DIR> [options]"
  echo
  echo "Options:"
  echo "  -t <tcl_name>   Use specified tcl script (default: baseline)"
  echo "                  Example: -t baseline  -> baseline.tcl"
  echo "                           -t foo       -> foo.tcl"
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
DESIGN_NAME="$1"
TECH_DIR="$2"
DESIGN_DIR="$3"
OUTPUT_DIR="$4"
shift 4

#######################################
# Optional arguments
#######################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t)
      [[ $# -lt 2 ]] && usage
      TCL_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

#######################################
# Derived paths
#######################################
TEMPLATE_FILE="${TCL_DIR}/${TCL_NAME}.tcl"

#######################################
# Sanity checks
#######################################
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: Template file not found: $TEMPLATE_FILE" >&2
  exit 2
fi

#######################################
# Prepare temporary TCL directory
# Preserve the full DESIGN_DIR path structure
#######################################
TEMP_TCL_DIR="${TCL_DIR}/temp/${DESIGN_NAME}/$(basename "$DESIGN_DIR")"
mkdir -p "$TEMP_TCL_DIR"

GENERATED_TCL_FILE="${TEMP_TCL_DIR}/${TCL_NAME}.tcl"

#######################################
# Generate TCL file from template
# Replace environment variable references with actual values
#######################################
echo "Generating TCL file: $GENERATED_TCL_FILE"

sed -e "s|\$::env(DESIGN_NAME)|\"${DESIGN_NAME}\"|g" \
    -e "s|\$::env(TECH_DIR)|\"${TECH_DIR}\"|g" \
    -e "s|\$::env(DESIGN_DIR)|\"${DESIGN_DIR}\"|g" \
    -e "s|\$::env(OUTPUT_DIR)|\"${OUTPUT_DIR}\"|g" \
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
echo "Running OpenROAD with generated TCL file..."
openroad \
  -threads "$(nproc)" \
  -no_init \
  -exit \
  "$GENERATED_TCL_FILE"
