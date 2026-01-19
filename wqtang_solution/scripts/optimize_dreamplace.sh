#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 7 ]; then
    echo "Usage: $0 <design_name> <TNS_weight, alpha> <power_weight, beta> <HPWL_weight, gamma> <input path> <output path> <approximate function>"
    exit 1
fi

# Parse arguments
DESIGN_NAME=$(basename $1)
ALPHA=$2
BETA=$3
GAMMA=$4
INPUT_PATH=$(realpath "$5")
OUTPUT_PATH=$6
mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$(realpath "$6")
APPROXIMATE_FUNCTION=$7

ASAP7_PATH=$(realpath "./testcases/ASAP7")
INPUT_DEF=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.def")
INPUT_VERILOG=$(realpath "${INPUT_PATH}/${DESIGN_NAME}.v")
INPUT_SDC=$(realpath "./testcases/${DESIGN_NAME}/${DESIGN_NAME}.sdc")

# Generate JSON configuration
JSON_FILE="${OUTPUT_PATH}/${DESIGN_NAME}.json"
LOG_FILE="${OUTPUT_PATH}/dreamplace.log"

# Collect library files
LIB_DIR="$ASAP7_PATH/LIB"
mapfile -t LIBS < <(find "$LIB_DIR" -name "*.lib" | sort)

# Collect LEF files: tech first, then ASAP7
TECHLEF_DIR="$ASAP7_PATH/techlef"
mapfile -t TECHLEFS < <(find "$TECHLEF_DIR" -maxdepth 1 -name "*.lef" | sort)

ASAP7_LEF_DIR="$ASAP7_PATH/LEF"
mapfile -t ASAP7_LEFS < <(find "$ASAP7_LEF_DIR" -name "*.lef" | sort)

# Build JSON array strings for libs
lib_json=""
for i in "${!LIBS[@]}"; do
  file=${LIBS[$i]}
  if [ $i -lt $((${#LIBS[@]}-1)) ]; then sep=","; else sep=""; fi
  lib_json+="    \"$file\"$sep"$'\n'
done

# Build JSON array string for LEFs
lef_json=""
# techlef entries (always comma)
for file in "${TECHLEFS[@]}"; do
  lef_json+="    \"$file\","$'\n'
done
# asap7/LEF entries
for i in "${!ASAP7_LEFS[@]}"; do
  file=${ASAP7_LEFS[$i]}
  if [ $i -lt $((${#ASAP7_LEFS[@]}-1)) ]; then sep=","; else sep=""; fi
  lef_json+="    \"$file\"$sep"$'\n'
done

# Generate the JSON configuration
cat > "$JSON_FILE" <<EOF
{
  "verilog_input"   : "$INPUT_VERILOG",
  "def_input"       : "$INPUT_DEF",
  "sdc_input"       : "$INPUT_SDC",
  "lib_input" : [
$lib_json  ],
  "lef_input"       : [
$lef_json  ],
  "gpu"              : 1,
  "random_seed"      : 123,
  "global_place_flag": 1,
  "enable_fillers"   : 0,
  "legalize_flag"    : 1,
  "detailed_place_flag": 1,
  "timing_opt_flag"  : 0,
  "enable_net_weighting": 0,
  "result_dir"       : "$OUTPUT_PATH",
  "plot_flag": 0,
  "random_center_init_flag": 0,
  "density_weight": 8e-5,
  "gp_noise_ratio": 0.025,
  "wire_resistance_per_micron": 2.4222e-02,
  "wire_capacitance_per_micron": 0.12918e-15,

  "Alpha":$ALPHA,
  "Beta":$BETA,
  "Gamma":$GAMMA,

  "macro_place_flag": 1,

  "global_place_stages": [
    {
      "num_bins_x": 0,
      "num_bins_y": 0,
      "iteration": 1000,
      "learning_rate": 0.01,
      "wirelength": "$APPROXIMATE_FUNCTION",
      "optimizer": "nesterov",
      "Llambda_density_weight_iteration": 1,
      "Lsub_iteration": 1
    }
  ],

  "timing_grad_opt_flag": 0,
  "timing_wns_factor": 1e5,
  "timing_tns_factor": 3e5,
  "timing_start_iteration": 100,
  "timing_finite_diff_epsilon": 0.5,
  "timing_finite_diff_n_path": 2
}
EOF

# Run the placer with the generated configuration
echo "Running DREAMPlace optimization..."
cd ./extpkgs/DREAMPlace_install/
python3 dreamplace/Placer.py "$JSON_FILE" > $LOG_FILE 2>&1
cd ../../


# Check if optimization was successful
OUTPUT_DEF=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.def")
OUTPUT_CHANGELIST=$(realpath "${OUTPUT_PATH}/${DESIGN_NAME}.changelist")
if [ $? -eq 0 ]; then
    echo "Optimization completed successfully!"
    # Output DEF file should be in results directory
    RESULT_DEF="${OUTPUT_PATH}/${DESIGN_NAME}.gp.def"
    if [ -f "$RESULT_DEF" ]; then
        mv $RESULT_DEF "$OUTPUT_DEF"
        OUTPUT_PARENT_PATH=$(dirname $OUTPUT_PATH)
        ORIGINAL_DEF="${OUTPUT_PARENT_PATH}/original/${DESIGN_NAME}.def"

        ./bin/gen_changelist "${ORIGINAL_DEF}" "${OUTPUT_DEF}" "${OUTPUT_CHANGELIST}"
        echo "Optimized DEF file: ${OUTPUT_DEF}"
        echo "Optimized CHANGELIST file: ${OUTPUT_CHANGELIST}"
        ./scripts/eval.sh "${OUTPUT_DEF}" ${INPUT_SDC} ${ASAP7_PATH} ${OUTPUT_PATH}
        
        # Call write_ans.sh to handle scoring and solution updates
        ./scripts/write_ans.sh "${DESIGN_NAME}" "${ORIGINAL_DEF}" "${OUTPUT_PATH}"
    else
        echo "Error: Optimized DEF file not found!"
        exit 1
    fi
else
    echo "Error: DREAMPlace optimization failed!"
    exit 1
fi
