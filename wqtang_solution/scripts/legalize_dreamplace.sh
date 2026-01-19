#!/bin/bash

# Check if all arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <input def> <input verilog> <input sdc> <output def>"
    exit 1
fi

# Parse arguments
INPUT_DEF=$(realpath "$1")
INPUT_VERILOG=$(realpath "$2")
INPUT_SDC=$(realpath "$3")
OUTPUT_DEF=$(realpath "$4")

# Get design name from input DEF basename (without extension)
INPUT_BASENAME=$(basename "$INPUT_VERILOG" .v)

# Get directory for output
OUTPUT_DIR=$(dirname "$OUTPUT_DEF")
mkdir -p "$OUTPUT_DIR"

ASAP7_PATH=$(realpath "./testcases/ASAP7")

# Generate JSON configuration
JSON_FILE="${OUTPUT_DIR}/${INPUT_BASENAME}_legalize.json"
LOG_FILE="${OUTPUT_DIR}/dreamplace.log"

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

# Generate the JSON configuration - LEGALIZATION ONLY
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
  "global_place_flag": 0,
  "enable_fillers"   : 0,
  "legalize_flag"    : 1,
  "detailed_place_flag": 0,
  "timing_opt_flag"  : 0,
  "enable_net_weighting": 0,
  "result_dir"       : "$OUTPUT_DIR",
  "plot_flag": 0,
  "random_center_init_flag": 0,
  "density_weight": 8e-5,
  "gp_noise_ratio": 0.025,
  "wire_resistance_per_micron": 2.4222e-02,
  "wire_capacitance_per_micron": 0.12918e-15,

  "Alpha":0,
  "Beta":0,
  "Gamma":0,

  "macro_place_flag": 0
}
EOF

# Run the placer with the generated configuration
echo "Running DREAMPlace legalization only..."
cd ./extpkgs/DREAMPlace_install/
python3 dreamplace/Placer.py "$JSON_FILE" > $LOG_FILE 2>&1
DREAMPLACE_EXIT_CODE=$?
cd ../../

# Check if legalization was successful
if [ $DREAMPLACE_EXIT_CODE -eq 0 ]; then
    # DREAMPlace outputs to <basename>.gp.def in the result_dir
    RESULT_DEF="${OUTPUT_DIR}/${INPUT_BASENAME}.gp.def"
    if [ -f "$RESULT_DEF" ]; then
        mv "$RESULT_DEF" "$OUTPUT_DEF"
        echo "Legalization completed successfully!"
        echo "Legalized DEF file: ${OUTPUT_DEF}"
        exit 0
    else
        echo "Error: Legalized DEF file not found at $RESULT_DEF!"
        exit 1
    fi
else
    echo "Error: DREAMPlace legalization failed!"
    exit 1
fi
