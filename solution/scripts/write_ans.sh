#!/bin/bash

# write_ans.sh - Simplified script to save best answer files based on TNS
# Usage: write_ans.sh <result_path> <real_output_path>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <design_name> <result_path> <output_path>"
    exit 1
fi

DESIGN_NAME=$1
RESULT_PATH=$2
OUTPUT_PATH=$3

# cd to solution directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SOLUTION_DIR"
echo "Current directory: $(pwd)"
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
# Extract TNS from metrics.csv
# Format: design,...,wns,tns,...
#######################################
# Get header to find tns column index
HEADER=$(head -1 "$METRICS_CSV")
TNS_COL=$(echo "$HEADER" | tr ',' '\n' | grep -n "^tns$" | cut -d: -f1)

if [ -z "$TNS_COL" ]; then
    echo "Error: Could not find 'tns' column in metrics.csv"
    exit 1
fi

# Extract TNS value from second line (data row)
CURRENT_TNS=$(tail -1 "$METRICS_CSV" | cut -d',' -f"$TNS_COL")

if [ -z "$CURRENT_TNS" ]; then
    echo "Error: Could not extract TNS value"
    CURRENT_TNS="N/A"
fi

echo "Current TNS: $CURRENT_TNS"

#######################################
# Log entry
#######################################
write_log() {
    local log_type="$1"
    echo "========================================" >> "$LOG_FILE"
    echo "$(date): $log_type" >> "$LOG_FILE"
    echo "Result Path: $RESULT_PATH" >> "$LOG_FILE"
    echo "Current TNS: $CURRENT_TNS" >> "$LOG_FILE"
    if [ -n "$EXISTING_TNS" ]; then
        echo "Existing TNS: $EXISTING_TNS" >> "$LOG_FILE"
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
    # Read existing TNS
    EXISTING_TNS=$(grep "^TNS = " "$SOL_SCORE_FILE" 2>/dev/null | sed 's/^TNS = //')
    
    if [ -z "$EXISTING_TNS" ] || [ "$EXISTING_TNS" = "N/A" ]; then
        if [ "$CURRENT_TNS" != "N/A" ]; then
            echo "Existing TNS is N/A, updating with valid TNS"
            write_log "REPLACING N/A"
            SHOULD_UPDATE=1
        fi
    elif [ "$CURRENT_TNS" != "N/A" ]; then
        # Compare TNS values (higher/less negative is better)
        BETTER=$(awk -v current="$CURRENT_TNS" -v existing="$EXISTING_TNS" 'BEGIN { print (current > existing) ? 1 : 0 }')
        
        if [ "$BETTER" = "1" ]; then
            echo "Current TNS ($CURRENT_TNS) is better than existing ($EXISTING_TNS)"
            write_log "BETTER SOLUTION FOUND"
            SHOULD_UPDATE=1
        else
            echo "Current TNS ($CURRENT_TNS) is not better than existing ($EXISTING_TNS)"
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
    echo "TNS = $CURRENT_TNS" > "$SOL_SCORE_FILE"
    echo "Source: $RESULT_PATH" >> "$SOL_SCORE_FILE"
    
    echo "Solution files updated:"
    echo "  - $SOL_DEF_FILE"
    echo "  - $SOL_SCORE_FILE"
    echo "  - TNS: $CURRENT_TNS"
else
    echo "Solution not updated (current TNS not better)"
fi

echo "write_ans.sh completed"
