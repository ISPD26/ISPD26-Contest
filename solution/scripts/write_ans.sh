#!/bin/bash

# write_ans.sh - Simplified script to save best answer files based on target metric
# Usage: write_ans.sh <design_name> <result_path> <output_path> [target_metric]

if [ $# -lt 3 ]; then
    echo "Usage: $0 <design_name> <result_path> <output_path> [target_metric]"
    echo "  target_metric: Column name to use for ranking (default: S_final)"
    echo "                 Examples: tns, wns, slew_over_sum, total_power, etc."
    exit 1
fi

DESIGN_NAME=$1
RESULT_PATH=$2
OUTPUT_PATH=$3
TARGET_METRIC=${4:-S_final}  # Default to "S_final" if not specified

# cd to solution directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SOLUTION_DIR"
# Extract design name from result path

# Set up paths
TEMP_OUTPUT_PATH="./output_temp/${DESIGN_NAME}"
LOG_FILE="${TEMP_OUTPUT_PATH}/write_ans.log"
touch "$LOG_FILE"
#######################################
# File paths
#######################################
METRICS_CSV="${RESULT_PATH}/metrics.csv"
DEF_FILE="${RESULT_PATH}/${DESIGN_NAME}.def"
VERILOG_FILE="${RESULT_PATH}/${DESIGN_NAME}.v"

# Solution file paths (ISPD26 format)
SOL_DEF_FILE="${OUTPUT_PATH}/${DESIGN_NAME}.def"
SOL_VERILOG_FILE="${OUTPUT_PATH}/${DESIGN_NAME}.v"

BEST_DIR="./output_temp/best_solutions/${DESIGN_NAME}"
SOL_SCORE_FILE="${BEST_DIR}/best.score"

mkdir -p "$BEST_DIR"
# Lock file
LOCK_FILE="./output_temp/${DESIGN_NAME}.lock"


# debug (print all variables)
# echo "DESIGN_NAME: $DESIGN_NAME"
# echo "RESULT_PATH: $RESULT_PATH"
# echo "OUTPUT_PATH: $OUTPUT_PATH"
# echo "METRICS_CSV: $METRICS_CSV"
# echo "DEF_FILE: $DEF_FILE"
# echo "VERILOG_FILE: $VERILOG_FILE"
# echo "SOL_DEF_FILE: $SOL_DEF_FILE"
# echo "SOL_VERILOG_FILE: $SOL_VERILOG_FILE"
# echo "BEST_DIR: $BEST_DIR"
# echo "BEST_SCORE_FILE: $BEST_SCORE_FILE"
# echo "LOCK_FILE: $LOCK_FILE"
# exit 0

#######################################
# Locking mechanism
#######################################
# Function to acquire lock with timeout
acquire_lock() {
    local timeout=300
    local count=0
    
    while [ $count -lt $timeout ]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    return 1
}

# Function to release lock
release_lock() {
    rmdir "$LOCK_FILE" 2>/dev/null
}

# Variable to track if lock is held
LOCK_HELD=0

# Function to cleanup on exit
cleanup() {
    if [ "$LOCK_HELD" = "1" ]; then
        release_lock
        LOCK_HELD=0
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

#######################################
# Check required files
#######################################
if [ ! -f "$DEF_FILE" ]; then
    echo "Error: No DEF file found in $RESULT_PATH"
    exit 1
fi

if [ ! -f "$METRICS_CSV" ]; then
    echo "Error: metrics.csv not found at $METRICS_CSV"
    exit 1
fi

#######################################
# Extract target metric from metrics.csv
#######################################
# Get header to find target column index (strip carriage returns for Windows-style line endings)
HEADER=$(head -1 "$METRICS_CSV" | tr -d '\r')
METRIC_COL=$(echo "$HEADER" | tr ',' '\n' | grep -n "^${TARGET_METRIC}$" | cut -d: -f1)

if [ -z "$METRIC_COL" ]; then
    echo "Error: Could not find '${TARGET_METRIC}' column in metrics.csv"
    echo "Available columns: $HEADER"
    exit 1
fi

# Extract metric value from second line (data row), strip carriage returns
CURRENT_VALUE=$(tail -1 "$METRICS_CSV" | tr -d '\r' | cut -d',' -f"$METRIC_COL")

if [ -z "$CURRENT_VALUE" ]; then
    echo "Error: Could not extract ${TARGET_METRIC} value"
    CURRENT_VALUE="N/A"
fi

echo "Target metric: $TARGET_METRIC"
echo "Current value: $CURRENT_VALUE"

#######################################
# Log entry
#######################################
write_log() {
    local log_type="$1"
    echo "========================================" >> "$LOG_FILE"
    echo "$(date): $log_type" >> "$LOG_FILE"
    echo "Result Path: $RESULT_PATH" >> "$LOG_FILE"
    echo "Target Metric: $TARGET_METRIC" >> "$LOG_FILE"
    echo "Current Value: $CURRENT_VALUE" >> "$LOG_FILE"
    if [ -n "$EXISTING_VALUE" ]; then
        echo "Existing Value: $EXISTING_VALUE" >> "$LOG_FILE"
    fi
    echo "========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

#######################################
# Determine if we should update
#######################################
SHOULD_UPDATE=0

if [ ! -f "$SOL_DEF_FILE" ] || [ ! -f "$SOL_SCORE_FILE" ]; then
    echo "No existing solution files found, creating initial solution"
    write_log "INITIAL SOLUTION"
    SHOULD_UPDATE=1
else
    # Read existing value
    EXISTING_VALUE=$(grep "^${TARGET_METRIC} = " "$SOL_SCORE_FILE" 2>/dev/null | sed "s/^${TARGET_METRIC} = //")
    
    if [ -z "$EXISTING_VALUE" ] || [ "$EXISTING_VALUE" = "N/A" ]; then
        if [ "$CURRENT_VALUE" != "N/A" ]; then
            echo "Existing value is N/A, updating with valid value"
            write_log "REPLACING N/A"
            SHOULD_UPDATE=1
        fi
    elif [ "$CURRENT_VALUE" != "N/A" ]; then
        # Compare values (higher/less negative is better)
        BETTER=$(awk -v current="$CURRENT_VALUE" -v existing="$EXISTING_VALUE" 'BEGIN { print (current > existing) ? 1 : 0 }')
        
        if [ "$BETTER" = "1" ]; then
            echo "Current $TARGET_METRIC ($CURRENT_VALUE) is better than existing ($EXISTING_VALUE)"
            write_log "BETTER SOLUTION FOUND"
            SHOULD_UPDATE=1
        else
            echo "Current $TARGET_METRIC ($CURRENT_VALUE) is not better than existing ($EXISTING_VALUE)"
            write_log "WORSE SOLUTION"
            SHOULD_UPDATE=0
        fi
    fi
fi

#######################################
# Update solution files if needed
#######################################
if [ "$SHOULD_UPDATE" = "1" ]; then
    echo "Updating solution files..."
    
    # Create solution directory
    mkdir -p "$OUTPUT_PATH"
    
    # Acquire lock
    echo "Acquiring lock..."
    if ! acquire_lock; then
        echo "Error: Could not acquire lock within timeout"
        exit 1
    fi
    LOCK_HELD=1
    echo "Lock acquired"
    
    # Copy DEF file
    cp "$DEF_FILE" "$SOL_DEF_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy DEF file"
        release_lock
        LOCK_HELD=0
        exit 1
    fi
    cp "$VERILOG_FILE" "$SOL_VERILOG_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy Verilog file"
        release_lock
        LOCK_HELD=0
        exit 1
    fi

    
    # Release lock
    release_lock
    LOCK_HELD=0
    echo "Lock released"
    
    # Write score file
    echo "${TARGET_METRIC} = $CURRENT_VALUE" > "$SOL_SCORE_FILE"
    echo "Source: $RESULT_PATH" >> "$SOL_SCORE_FILE"
    
    echo "Solution files updated:"
    echo "  - $SOL_DEF_FILE"
    echo "  - $SOL_SCORE_FILE"
    echo "  - ${TARGET_METRIC}: $CURRENT_VALUE"
else
    echo "Solution not updated (current $TARGET_METRIC not better)"
fi

echo "write_ans.sh completed"
