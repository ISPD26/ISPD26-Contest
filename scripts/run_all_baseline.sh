#!/bin/bash
# =====================================================
# Run ISPD26 OpenROAD baseline flow for multiple benchmarks
# =====================================================

# Set the top project directory
export TOP_PROJ_DIR="/ISPD26-Contest"
export PROJ_DIR="${TOP_PROJ_DIR}/scripts"
OPENROAD_BIN="/OpenROAD/build/bin/openroad"

# List of benchmarks: each line is "<design_name> <folder_name>"
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

# benchmarks=(
#   "aes_cipher_top TCP_250_UTIL_0.40"
#   "aes_cipher_top_v2 TCP_200_UTIL_0.40"
#   "ariane TCP_900_UTIL_0.30"
#   "ariane_v2 TCP_950_UTIL_0.45"
#   "bsg_chip TCP_1200_UTIL_0.30"
#   "bsg_chip_v2 TCP_1300_UTIL_0.50"
#   "jpeg_encoder TCP_350_UTIL_0.70"
#   "jpeg_encoder_v2 TCP_450_UTIL_0.65"
# )

# Loop over benchmarks
for bm in "${benchmarks[@]}"; do
  # Split into design name and folder
  export DESIGN_NAME=$(echo $bm | awk '{print $1}')
  export FOLDER_NAME=$(echo $bm | awk '{print $2}')

  echo "==========================================="
  echo "Running benchmark: $DESIGN_NAME → $FOLDER_NAME"
  echo "==========================================="
  cd "${PROJ_DIR}/${DESIGN_NAME}"
  echo "Current directory: $(pwd)"

  # Create output folder
  mkdir -p "${FOLDER_NAME}"

  # Set log & output paths
  export LOG_FILE="${FOLDER_NAME}/evaluation.log"
  export METRICS_CSV="${FOLDER_NAME}/metrics.csv"
  export CONGESTION_REPORT="${FOLDER_NAME}/congestion_report.rpt"

  # Run OpenROAD baseline flow
#   ${OPENROAD_BIN} -exit "${PROJ_DIR}/evaluation_baseline.tcl" | tee "${LOG_FILE}"
  ${OPENROAD_BIN} -exit "${PROJ_DIR}/evaluation_baseline.tcl" > "${LOG_FILE}"

  # Parse log to CSV
  python3 "${PROJ_DIR}/parse_log.py" "${LOG_FILE}" --csv "${METRICS_CSV}"

  echo "Benchmark $DESIGN_NAME completed."
  echo
done

echo "All benchmarks finished."
