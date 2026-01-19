#!/bin/bash

# write_ans_ppa.sh - Script to safely write answer files with locking mechanism (PPA metrics only, no displacement penalty)
# Usage: write_ans_ppa.sh <design_name> <original_def> <result_path>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <design_name> <original_def> <result_path>"
    exit 1
fi

DESIGN_NAME=$1
ORIGINAL_DEF=$2
RESULT_PATH=$3
DESIGN_NAME_FROM_PATH=$(basename "$RESULT_PATH")
# Set up log file path and get design name from output path
LOG_FILE="./output/${DESIGN_NAME}/write_ans_ppa.log"
mkdir -p "./output/${DESIGN_NAME}"

# Function to write detailed log entry
write_detailed_log() {
    local log_type="$1"
    local current_score="$2"
    local existing_score="$3"

    echo "========================================" >> "$LOG_FILE"
    echo "$(date): $log_type" >> "$LOG_FILE"
    echo "Design: $DESIGN_NAME_FROM_PATH" >> "$LOG_FILE"
    echo "Current Score: S = $current_score" >> "$LOG_FILE"
    if [ "$existing_score" != "" ]; then
        echo "Existing Score: S = $existing_score" >> "$LOG_FILE"
    fi
    echo "Improvements:" >> "$LOG_FILE"
    echo "  - TNS Improvement: (${REVISED_TNS}-(${ORIGINAL_TNS}))/|${ORIGINAL_TNS}| = ${TNS_IMPR}%" >> "$LOG_FILE"
    echo "  - Power Improvement: (${ORIGINAL_POWER}-${REVISED_POWER})/${ORIGINAL_POWER} = ${POWER_IMPR}%" >> "$LOG_FILE"
    echo "  - HPWL Improvement: (${ORIGINAL_HPWL}-${REVISED_HPWL})/${ORIGINAL_HPWL} = ${HPWL_IMPR}%" >> "$LOG_FILE"
    echo "PPA Formula: $PPA_FORMULA" >> "$LOG_FILE"
    echo "P Metric: $P_METRIC" >> "$LOG_FILE"
    echo "Final Score (PPA only): S = $current_score" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Define file paths
DEF_FILE="${RESULT_PATH}/${DESIGN_NAME}.def"
CHANGELIST_FILE="${RESULT_PATH}/${DESIGN_NAME}.changelist"
REVISED_PPAD="${RESULT_PATH}/PPAD.out"
REVISED_PPA="${RESULT_PATH}/PPA.out"
ORIGINAL_PPA="$(dirname "$ORIGINAL_DEF")/PPAD.out"

# Define solution file paths (using _ppa suffix to distinguish from regular solution)
SOL_DEF_FILE="./${DESIGN_NAME}.sol_ppa.def"
SOL_CHANGELIST_FILE="./${DESIGN_NAME}.sol_ppa.changelist"
SOL_SCORE_FILE="./output/${DESIGN_NAME}/best_ppa.score"

# Define lock file in output directory
LOCK_FILE="./output/${DESIGN_NAME}/${DESIGN_NAME}_ppa.lock"

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


# Check if required files exist
if [ ! -f "$DEF_FILE" ]; then
    echo "Error: DEF file $DEF_FILE not found"
    exit 1
fi

if [ ! -f "$CHANGELIST_FILE" ]; then
    echo "Error: CHANGELIST file $CHANGELIST_FILE not found"
    exit 1
fi

# Calculate score if PPA files are available (only using PPA metrics, no displacement)
CURRENT_SCORE="N/A"
if [ -f "$REVISED_PPAD" ] || [ -f "${RESULT_PATH}/PPA.out" ]; then
    # Check if PPAD.out already exists, if not run scoring script
    if [ -f "$REVISED_PPAD" ]; then
        echo "PPAD.out already exists, using it for PPA metrics"
    # Special handling for "original" design
    elif [ "$DESIGN_NAME_FROM_PATH" == "original" ]; then
        echo "Handling 'original' design - using existing PPAD.out for PPA metrics"
        # For original, PPAD.out should already exist with all metrics
        if [ ! -f "$REVISED_PPAD" ]; then
            # If PPAD.out doesn't exist, copy from REVISED_PPA
            cp "$REVISED_PPA" "$REVISED_PPAD"
        fi
    else
        echo "PPAD.out not found, running scoring script..."
        ./scripts/scoring.sh "${DESIGN_NAME}" "${ORIGINAL_DEF}" "${DEF_FILE}" "${ORIGINAL_PPA}" "${REVISED_PPA}"
    fi

    # Read alpha, beta, gamma values from ./output/<design_name>/abg.values
    ABG_VALUES_PATH="./output/${DESIGN_NAME}/abg.values"
    if [ ! -f "$ABG_VALUES_PATH" ]; then
        echo "Error: $ABG_VALUES_PATH file not found"
        CURRENT_SCORE="N/A"
        TNS_IMPR="N/A"
        POWER_IMPR="N/A"
        HPWL_IMPR="N/A"
        P_METRIC="N/A"
        PPA_FORMULA="N/A"
    else
        source "$ABG_VALUES_PATH"
        if [ -z "$ALPHA" ] || [ -z "$BETA" ] || [ -z "$GAMMA" ]; then
            echo "Error: Could not read ALPHA, BETA, GAMMA from $ABG_VALUES_PATH"
            CURRENT_SCORE="N/A"
            TNS_IMPR="N/A"
            POWER_IMPR="N/A"
            HPWL_IMPR="N/A"
            P_METRIC="N/A"
            PPA_FORMULA="N/A"
        else
            echo "Using scoring parameters: ALPHA=$ALPHA, BETA=$BETA, GAMMA=$GAMMA"

            # Extract original metrics from original PPA file
            ORIGINAL_TNS=$(grep "TNS:" "$ORIGINAL_PPA" | awk '{print $2}')
            ORIGINAL_POWER=$(grep "Power:" "$ORIGINAL_PPA" | awk '{print $2}')
            ORIGINAL_HPWL=$(grep "HPWL:" "$ORIGINAL_PPA" | awk '{print $2}')

            # Extract revised metrics from revised PPA file (using PPAD.out which has all metrics)
            REVISED_TNS=$(grep "TNS:" "$REVISED_PPAD" | awk '{print $2}')
            REVISED_POWER=$(grep "Power:" "$REVISED_PPAD" | awk '{print $2}')
            REVISED_HPWL=$(grep "HPWL:" "$REVISED_PPAD" | awk '{print $2}')

            # Calculate improvements
            TNS_IMPR=$(awk -v orig="$ORIGINAL_TNS" -v rev="$REVISED_TNS" 'BEGIN {
                if (orig < 0) {
                    printf "%.6f", ((rev - orig) / -orig) * 100
                } else {
                    printf "0.000000"
                }
            }')

            POWER_IMPR=$(awk -v orig="$ORIGINAL_POWER" -v rev="$REVISED_POWER" 'BEGIN {
                if (orig > 0) {
                    printf "%.6f", ((orig - rev) / orig) * 100
                } else {
                    printf "0.000000"
                }
            }')

            HPWL_IMPR=$(awk -v orig="$ORIGINAL_HPWL" -v rev="$REVISED_HPWL" 'BEGIN {
                if (orig > 0) {
                    printf "%.6f", ((orig - rev) / orig) * 100
                } else {
                    printf "0.000000"
                }
            }')

            # Handle missing HPWL values
            if [ -z "$ORIGINAL_HPWL" ]; then
                ORIGINAL_HPWL="N/A"
            fi
            if [ -z "$REVISED_HPWL" ]; then
                REVISED_HPWL="N/A"
            fi
            if [ -z "$HPWL_IMPR" ] || [ "$ORIGINAL_HPWL" = "N/A" ] || [ "$REVISED_HPWL" = "N/A" ]; then
                HPWL_IMPR="N/A"
            fi

            # Calculate P metric: P = α*TNS_IMPR + β*POWER_IMPR + γ*HPWL_IMPR
            P_METRIC=$(awk -v alpha="$ALPHA" -v beta="$BETA" -v gamma="$GAMMA" \
                       -v tns="$TNS_IMPR" -v power="$POWER_IMPR" -v hpwl="$HPWL_IMPR" 'BEGIN {
                if (tns == "N/A" || power == "N/A" || hpwl == "N/A") {
                    printf "N/A"
                } else {
                    printf "%.6f", alpha * tns + beta * power + gamma * hpwl
                }
            }')

            # Set PPA formula for logging
            PPA_FORMULA="alpha*TNS + beta*Power + gamma*HPWL = ${ALPHA}*${TNS_IMPR} + ${BETA}*${POWER_IMPR} + ${GAMMA}*${HPWL_IMPR} = ${P_METRIC}"

            # Calculate S metric: S = 1000*P (NO displacement penalty for PPA-only scoring)
            CURRENT_SCORE=$(awk -v p="$P_METRIC" 'BEGIN {
                if (p == "N/A") {
                    printf "N/A"
                } else {
                    printf "%.6f", 1000 * p
                }
            }')

            echo "Calculated PPA-only score: $CURRENT_SCORE"
        fi
    fi
else
    echo "Warning: PPAD.out file not found, cannot calculate score"
    CURRENT_SCORE="N/A"
    TNS_IMPR="N/A"
    POWER_IMPR="N/A"
    HPWL_IMPR="N/A"
    P_METRIC="N/A"
    PPA_FORMULA="N/A"
fi


# Determine if we should update the solution
SHOULD_UPDATE=0

# Check if solution files don't exist (first run)
if [ ! -f "$SOL_DEF_FILE" ] || [ ! -f "$SOL_CHANGELIST_FILE" ] || [ ! -f "$SOL_SCORE_FILE" ]; then
    echo "No existing PPA solution files found, creating initial solution"
    write_detailed_log "INITIAL SOLUTION" "$CURRENT_SCORE" ""
    SHOULD_UPDATE=1
else
    # Compare scores - extract numeric value from current score
    if [ -f "$SOL_SCORE_FILE" ]; then
        # Extract the S value from the existing solution score file
        EXISTING_SCORE=$(grep "^S = " "$SOL_SCORE_FILE" | sed 's/^S = //' | sed 's/"$//')

        # Handle special case: existing score is N/A but current score is not N/A
        if [ "$EXISTING_SCORE" = "N/A" ] && [ "$CURRENT_SCORE" != "N/A" ]; then
            echo "Existing score is N/A but current score ($CURRENT_SCORE) is valid, updating solution"
            write_detailed_log "REPLACING N/A WITH VALID SCORE" "$CURRENT_SCORE" "$EXISTING_SCORE"
            SHOULD_UPDATE=1
        else
            # Handle N/A scores for numeric comparison
            if [ "$EXISTING_SCORE" = "N/A" ]; then
                EXISTING_SCORE_NUM=-999999
            else
                EXISTING_SCORE_NUM=$EXISTING_SCORE
            fi

            if [ "$CURRENT_SCORE" = "N/A" ]; then
                CURRENT_SCORE_NUM=-999999
            else
                CURRENT_SCORE_NUM=$CURRENT_SCORE
            fi

            # Compare scores using awk for floating point comparison
            BETTER=$(awk -v current="$CURRENT_SCORE_NUM" -v existing="$EXISTING_SCORE_NUM" 'BEGIN { print (current > existing) ? 1 : 0 }')

            if [ "$BETTER" = "1" ]; then
                echo "Current PPA score ($CURRENT_SCORE) is better than existing PPA score ($EXISTING_SCORE)"
                write_detailed_log "BETTER SOLUTION FOUND" "$CURRENT_SCORE" "$EXISTING_SCORE"
                SHOULD_UPDATE=1
            else
                echo "Current PPA score ($CURRENT_SCORE) is not better than existing PPA score ($EXISTING_SCORE)"
                write_detailed_log "WORSE SOLUTION" "$CURRENT_SCORE" "$EXISTING_SCORE"
                SHOULD_UPDATE=0
            fi
        fi
    else
        echo "No existing PPA score file found, updating solution"
        write_detailed_log "NO EXISTING SCORE FILE" "$CURRENT_SCORE" ""
        SHOULD_UPDATE=1
    fi
fi

# Update solution files if needed
if [ "$SHOULD_UPDATE" = "1" ]; then
    echo "Updating PPA solution files..."

    # Acquire lock only for writing .sol.def and .sol.changelist files
    echo "Attempting to acquire lock for $DESIGN_NAME (PPA)..."
    if ! acquire_lock; then
        echo "Error: Could not acquire lock within timeout period"
        exit 1
    fi
    LOCK_HELD=1
    echo "Lock acquired successfully"

    # Copy DEF file
    cp "$DEF_FILE" "$SOL_DEF_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy DEF file"
        release_lock
        LOCK_HELD=0
        exit 1
    fi

    # Copy CHANGELIST file
    cp "$CHANGELIST_FILE" "$SOL_CHANGELIST_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy CHANGELIST file"
        release_lock
        LOCK_HELD=0
        exit 1
    fi

    # Release lock after writing .sol files
    release_lock
    LOCK_HELD=0
    echo "Lock released after writing .sol files"

    # Create simple score file for solution
    echo "S = $CURRENT_SCORE" > "$SOL_SCORE_FILE"

    # Copy the PPAD file as best_ppa.ppad to output path
    if [ -f "$REVISED_PPAD" ]; then
        BEST_PPA_FILE="./output/${DESIGN_NAME}/best_ppa.ppad"

        # Copy PPAD.out to best_ppa.ppad
        cp "$REVISED_PPAD" "$BEST_PPA_FILE"

        if [ $? -eq 0 ]; then
            echo "  - Created best_ppa.ppad at ./output/${DESIGN_NAME}/best_ppa.ppad"
        else
            echo "Warning: Failed to create best_ppa.ppad"
        fi
    else
        echo "Warning: No PPAD.out file found to copy as best_ppa.ppad"
    fi

    echo "PPA solution files updated successfully:"
    echo "  - $SOL_DEF_FILE"
    echo "  - $SOL_CHANGELIST_FILE"
    echo "  - $SOL_SCORE_FILE"
    echo "  - ./output/${DESIGN_NAME}/best_ppa.ppad"
    echo "  - PPA Score: $CURRENT_SCORE"
else
    echo "PPA solution files not updated (current score not better than existing)"
fi

echo "write_ans_ppa.sh completed successfully"
