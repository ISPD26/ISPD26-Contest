#!/usr/bin/env bash
set -euo pipefail

RUN_SH="/ISPD26-Contest/solution/run.sh"

TECH_DIR="/ISPD26-Contest/Platform/ASAP7"
BENCH_ROOT="/ISPD26-Contest/Benchmarks"
OUT_ROOT="/ISPD26-Contest/output"

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

if [[ ! -x "$RUN_SH" ]]; then
  echo "Error: run.sh not found or not executable: $RUN_SH" >&2
  exit 2
fi

echo "RUN_SH   = $RUN_SH"
echo "TECH_DIR = $TECH_DIR"
echo "BENCH    = $BENCH_ROOT"
echo "OUT      = $OUT_ROOT"
echo

DESIGN_FILTER=""
PASS_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --design)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Error: --design requires a value" >&2
        exit 2
      fi
      DESIGN_FILTER="$1"
      shift
      ;;
    -h)
      echo "Usage:"
      echo "  $0 [--design <design_name>] [run.sh options...]"
      echo "Examples:"
      echo "  $0"
      echo "  $0 --design aes_cipher_top"
      echo "  $0 --design ariane RUN_BASELINE=0"
      exit 0
      ;;
    *)
      PASS_ARGS+=("$1")
      shift
      ;;
  esac
done


failures=()

current_dir=$(pwd)

for item in "${benchmarks[@]}"; do
  design_name="${item%% *}"
  if [[ -n "$DESIGN_FILTER" && "$design_name" != "$DESIGN_FILTER" ]]; then
    # echo "[SKIP] design filter: $design_name (want: $DESIGN_FILTER)"
    continue
  fi
  scenario="${item#* }"

  design_dir="$BENCH_ROOT/$design_name/$scenario"
  out_dir="$OUT_ROOT/$design_name/$scenario"
  log_file="$out_dir/run.log"

  mkdir -p "$out_dir"

  echo "============================================================"
  echo "[RUN] $design_name / $scenario"
  echo "  design_dir: $design_dir"
  echo "  out_dir   : $out_dir"
  echo "  log       : $log_file"
  echo "------------------------------------------------------------"

  if [[ ! -d "$design_dir" ]]; then
    echo "[SKIP] design_dir not found: $design_dir"
    failures+=("$design_name/$scenario (missing design_dir)")
    continue
  fi

  set +e
  "$RUN_SH" "$design_name" "$TECH_DIR" "$design_dir" "$out_dir" "${PASS_ARGS[@]}" | tee "$log_file"
  rc=${PIPESTATUS[0]}
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "[FAIL] rc=$rc  ($design_name/$scenario)" | tee -a "$log_file"
    failures+=("$design_name/$scenario (rc=$rc)")
  else
    echo "[OK]   ($design_name/$scenario)" | tee -a "$log_file"
    cd "/ISPD26-Contest/scripts/${design_name}"
    source eval.sh
    cd "$current_dir"
  fi
done

echo
echo "============================= SUMMARY ============================="
if [[ ${#failures[@]} -eq 0 ]]; then
  echo "All benchmarks passed."
  exit 0
else
  echo "Failed benchmarks:"
  for f in "${failures[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
