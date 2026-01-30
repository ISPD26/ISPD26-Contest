#!/usr/bin/env bash
# set -euo pipefail

#######################################
# Path settings
#######################################
SOLUTION_DIR="/ISPD26-Contest/solution"
TECH_DIR="/ISPD26-Contest/Platform/ASAP7"
BENCH_ROOT="/ISPD26-Contest/Benchmarks"
OUT_ROOT="/ISPD26-Contest/solution/output"
TEST_DIR="/ISPD26-Contest/solution/test"

#######################################
# Default options
#######################################
TCL_NAME="baseline"
RUN_SCRIPT="run_ori.sh"

#######################################
# Benchmark list
# Format: "<design_name> <scenario>"
#######################################
benchmarks=(
  "aes_cipher_top TCP_250_UTIL_0.40"
  "aes_cipher_top_v2 TCP_200_UTIL_0.40"
  "ariane TCP_900_UTIL_0.30"
  "ariane_v2 TCP_950_UTIL_0.45"
  "bsg_chip TCP_1200_UTIL_0.30"
  "bsg_chip_v2 TCP_1300_UTIL_0.50"
  "jpeg_encoder TCP_350_UTIL_0.70"
  "jpeg_encoder_v2 TCP_450_UTIL_0.65"
)

#######################################
# Helper: list available designs
#######################################
list_available_designs() {
  echo "Available designs:"
  for entry in "${benchmarks[@]}"; do
    read -r design _ <<< "$entry"
    echo "  - $design"
  done | sort -u
}

#######################################
# Usage
#######################################
usage() {
  echo "Usage:"
  echo "  $0 -a [-t <tcl_name>] [-s <script>]"
  echo "  $0 -d <design1> <design2> ... [-t <tcl_name>] [-s <script>]"
  echo
  echo "Options:"
  echo "  -a               Run all benchmark cases"
  echo "  -d <design...>   Run specified design(s)"
  echo "  -t <tcl_name>    Use specified tcl script (default: baseline)"
  echo "  -s <script>      Use specified run script (default: run.sh)"
  echo "                   Use 'wq' for run_wqtang.sh"
  echo
  list_available_designs
  exit 1
}

#######################################
# Argument parsing
#######################################
run_all=false
declare -a selected_designs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a)
      run_all=true
      shift
      ;;
    -d)
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        selected_designs+=("$1")
        shift
      done
      ;;
    -t)
      [[ $# -lt 2 ]] && usage
      TCL_NAME="$2"
      shift 2
      ;;
    -s)
      [[ $# -lt 2 ]] && usage
      if [[ "$2" == "wq" ]]; then
        RUN_SCRIPT="run.sh"
      else
        RUN_SCRIPT="$2"
      fi
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

#######################################
# Sanity checks
#######################################
if [[ "$run_all" = false && ${#selected_designs[@]} -eq 0 ]]; then
  echo "Error: must specify -a or -d"
  usage
fi

RUN_SH="$SOLUTION_DIR/$RUN_SCRIPT"

if [[ ! -x "$RUN_SH" ]]; then
  echo "Error: $RUN_SCRIPT not found or not executable: $RUN_SH" >&2
  exit 2
fi

#######################################
# Helper: check if design is selected
#######################################
is_selected_design() {
  local design="$1"
  for d in "${selected_designs[@]}"; do
    [[ "$d" == "$design" ]] && return 0
  done
  return 1
}

#######################################
# Main loop
#######################################
current_dir=$(pwd)

for entry in "${benchmarks[@]}"; do
  read -r design_name scenario <<< "$entry"

  if [[ "$run_all" = false ]]; then
    if ! is_selected_design "$design_name"; then
      continue
    fi
  fi

  design_dir="$BENCH_ROOT/$design_name/$scenario"
  out_dir="$OUT_ROOT/${TCL_NAME}/$design_name/$scenario"
  log_file="$out_dir/run.log"

  echo "=================================================="
  echo "Running: $design_name / $scenario"
  echo "Script : $RUN_SCRIPT"
  echo "Tcl    : ${TCL_NAME}.tcl"
  echo "Design dir: $design_dir"
  echo "Output dir: $out_dir"
  echo "Log file : $log_file"
  echo "=================================================="

  mkdir -p "$out_dir"

  ###################################
  # Step 1: run main flow
  ###################################
  "$RUN_SH" \
    "$design_dir" \
    "$TECH_DIR" \
    "$out_dir" \
    "$design_name" \
    -t "$TCL_NAME" \
    > "$log_file"

  ###################################
  # Step 2: run evaluation script
  ###################################
  # eval_dir="/ISPD26-Contest/scripts/${design_name}"

  # if [[ -d "$eval_dir" && -f "$eval_dir/eval.sh" ]]; then
  #   cd "$eval_dir"
  #   echo
  #   echo "Running evaluation..."
  #   echo
  #   source eval.sh ${TCL_NAME}
  #   cd "$current_dir"

  #   python "$TEST_DIR/cal_total_score.py" "$out_dir"
    
  # else
  #   echo "Warning: eval.sh not found for $design_name"
  # fi
  
  ${SOLUTION_DIR}/scripts/eval.sh \
    "$design_dir" \
    "$TECH_DIR" \
    "$out_dir" \
    "$design_name" \
    
  python "$TEST_DIR/cal_total_score.py" "$out_dir"
done
