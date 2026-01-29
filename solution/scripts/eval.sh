#!/usr/bin/env bash
#######################################
# General evaluation script
# Usage: eval.sh <DESIGN_DIR> <TECH_DIR> <OUTPUT_DIR> <DESIGN_NAME>
#
# Arguments:
#   DESIGN_DIR  - Path to benchmark design folder (e.g., /ISPD26-Contest/Benchmarks/ariane/TCP_900_UTIL_0.30)
#   TECH_DIR    - Path to technology files (e.g., /ISPD26-Contest/Platform/ASAP7)
#   OUTPUT_DIR  - Path to output directory containing .def and .v files
#   DESIGN_NAME - Name of the design (e.g., ariane)
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(dirname "$SCRIPT_DIR")"

#######################################
# Argument parsing
#######################################
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <DESIGN_DIR> <TECH_DIR> <OUTPUT_DIR> <DESIGN_NAME>"
  exit 1
fi

DESIGN_DIR="$1"
TECH_DIR="$2"
OUTPUT_DIR="$3"
DESIGN_NAME="$4"

#######################################
# Derived paths
#######################################
GENERATED_DIR="${OUTPUT_DIR}/tcl"
GENERATED_EVALUATION_TCL="${GENERATED_DIR}/evaluation.tcl"
GENERATED_LIB_SETUP_TCL="${GENERATED_DIR}/lib_setup.tcl"
GENERATED_DESIGN_SETUP_TCL="${GENERATED_DIR}/design_setup.tcl"

LOG_FILE="${OUTPUT_DIR}/evaluation.log"
METRICS_CSV="${OUTPUT_DIR}/metrics.csv"

#######################################
# Generate TCL files from templates
#######################################
mkdir -p "${GENERATED_DIR}"

# Generate lib_setup.tcl
sed -e "s|__TECH_DIR__|${TECH_DIR}|g" \
    "${SCRIPT_DIR}/lib_setup.tcl" > "${GENERATED_LIB_SETUP_TCL}"

# Generate design_setup.tcl
sed -e "s|__DESIGN_DIR__/contest.sdc|${SOLUTION_DIR}/output_temp/${DESIGN_NAME}/contest.sdc|g" \
    -e "s|__DESIGN_DIR__|${DESIGN_DIR}|g" \
    -e "s|__OUTPUT_DIR__|${OUTPUT_DIR}|g" \
    -e "s|__DESIGN_NAME__|${DESIGN_NAME}|g" \
    "${SCRIPT_DIR}/design_setup.tcl" > "${GENERATED_DESIGN_SETUP_TCL}"

# Generate evaluation.tcl
sed -e "s|__DESIGN_NAME__|${DESIGN_NAME}|g" \
    -e "s|__OUTPUT_DIR__|${OUTPUT_DIR}|g" \
    -e "s|__SCRIPT_DIR__|${GENERATED_DIR}|g" \
    "${SCRIPT_DIR}/evaluation.tcl" > "${GENERATED_EVALUATION_TCL}"

#######################################
# Run evaluation
#######################################
echo "Evaluating: $DESIGN_NAME"
echo "Design dir: $DESIGN_DIR"
echo "Output dir: $OUTPUT_DIR"
echo "Log file: $LOG_FILE"
echo

mkdir -p "${OUTPUT_DIR}"
/OpenROAD/build/bin/openroad -exit "${GENERATED_EVALUATION_TCL}" > "${LOG_FILE}"

# Parse log to CSV
python3 "${SCRIPT_DIR}/parse_log.py" "${LOG_FILE}" --csv "${METRICS_CSV}"

# Calculate total score
python3 "${SOLUTION_DIR}/test/cal_total_score.py" "$OUTPUT_DIR"
