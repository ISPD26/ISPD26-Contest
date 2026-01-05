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
TCL_FILE="${TCL_DIR}/${TCL_NAME}.tcl"

#######################################
# Sanity checks
#######################################
if [[ ! -f "$TCL_FILE" ]]; then
  echo "Error: Tcl script not found: $TCL_FILE" >&2
  exit 2
fi

#######################################
# Export environment variables for Tcl
#######################################
export DESIGN_NAME TECH_DIR DESIGN_DIR OUTPUT_DIR

#######################################
# Prepare output directory
#######################################
mkdir -p "$OUTPUT_DIR"

#######################################
# Run OpenROAD
#######################################
openroad \
  -threads "$(nproc)" \
  -no_init \
  -exit \
  "$TCL_FILE"
