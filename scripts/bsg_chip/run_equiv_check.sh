#!/bin/bash
OR_EXE="/OpenROAD/build/bin/openroad"
export TOP_PROJ_DIR="/ISPD26-Contest"
export PROJ_DIR="${TOP_PROJ_DIR}/scripts"
export DESIGN_NAME="bsg_chip_v2"
export FOLDER_NAME="TCP_1300_UTIL_0.50"

# Run OpenROAD and capture output to log file
mkdir ${FOLDER_NAME} -p
LOG_FILE="${FOLDER_NAME}/equiv_cells.log"
echo "Running OpenROAD..."
$OR_EXE -exit ${PROJ_DIR}/run_equiv_check.tcl 2>&1 | tee $LOG_FILE

echo "Done!"
