export TOP_PROJ_DIR="/ISPD26-Contest"
export PROJ_DIR="${TOP_PROJ_DIR}/scripts"

export DESIGN_NAME="bsg_chip"
export FOLDER_NAME="TCP_1200_UTIL_0.30"

OUT_DIR="${TOP_PROJ_DIR}/solution/output/${DESIGN_NAME}/${FOLDER_NAME}"

mkdir -p "${OUT_DIR}"
export LOG_FILE="${OUT_DIR}/evaluation.log"
export METRICS_CSV="${OUT_DIR}/metrics.csv"
export CONGESTION_REPORT="${OUT_DIR}/congestion_report.rpt"
/OpenROAD/build/bin/openroad -exit ${PROJ_DIR}/evaluation.tcl > ${LOG_FILE}

# output metrics to csv
python3 ${PROJ_DIR}/parse_log.py ${LOG_FILE} --csv ${METRICS_CSV}



