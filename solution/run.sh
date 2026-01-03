#!/usr/bin/env bash

usage() {
  cat >&2 << 'EOF'
Usage:
  ./run.sh <design_name> <tech_dir> <design_dir> <output_dir> [options]

Positional arguments (required):
  design_name
      Example: aes_cipher_top

  tech_dir
      Example: /ISPD26-Contest/Platform/ASAP7

  design_dir
      Example: /ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40

  output_dir
      Example: /ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40

Options (optional):
  RUN_BASELINE=0|1
      Whether to run baseline flow (default: 1)

  -h
      Show this help message and exit

Full example:
  ./run.sh aes_cipher_top \
    /ISPD26-Contest/Platform/ASAP7 \
    /ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40 \
    /ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40

With options:
  ./run.sh aes_cipher_top \
    /ISPD26-Contest/Platform/ASAP7 \
    /ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40 \
    /ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40 \
    RUN_BASELINE=0
EOF
}

# Check for correct number of arguments
if [[ $# -lt 4 ]]; then
  usage
  exit 2
fi

# Assign input arguments to variables
DESIGN_NAME="$1"
TECH_DIR="$2"
DESIGN_DIR="$3"
OUTPUT_DIR="$4"
shift 4

# set global environment variables for tcl scripts
export DESIGN_NAME TECH_DIR DESIGN_DIR OUTPUT_DIR

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# ---- optional flags / hints ----
RUN_BASELINE=1

for arg in "$@"; do
  case "$arg" in
    RUN_BASELINE=*)
      RUN_BASELINE="${arg#*=}"
      ;;
    -h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

# Run the baseline step
if [[ "$RUN_BASELINE" -eq 1 ]]; then
  /ISPD26-Contest/run/baseline/main.sh
  echo "Baseline step completed."
fi

echo "run.sh completed successfully."