## Library Parser (ASAP7 LIB/LEF)

### Overview
This folder contains two scripts that parse standard-cell libraries from ASAP7 `.LIB` and `.LEF` files and produce consolidated JSON artifacts for downstream flows.

- **`lib_parser.py`**: parses `.LIB` (timing/capacitance) and `.LEF` (geometry) to build a per-cell map.
- **`parse_cell_info.py`**: post-processes the raw map to normalize pin names, infer cell type and drive/load, and build a compact type index.
- **`extract_lib_to_csv.py`**: extracts timing and power lookup table data from Liberty files for neural network training.

In the rest of this README, we call the consolidated library JSON "lib info". The current implementation of `lib_parser.py` writes it as `output.json` in this directory.

### Prerequisites
- Python 3.8+
- Input directories (relative to this folder):
  - `../../testcases/ASAP7/LIB/` — Liberty files (.lib)
  - `../../testcases/ASAP7/LEF/` — LEF files (.lef)

Ensure these directories exist and contain the relevant ASAP7 files before running the scripts.

### Quick start
Run from this directory:

```bash
python lib_parser.py
# The script writes ./lib_info.json
python parse_cell_info.py

python extract_lib_to_csv.py
```

This will generate the following files in the current folder:
- `lib_info.json` — raw lib info JSON produced by `lib_parser.py`.
- `cell_info_map.json` — cleaned/augmented cell info map.
- `ctype2id.json` — mapping from normalized cell type string to integer id.

- `delay_raw.csv`: Raw timing data with columns `[cell_type, from_pin, to_pin, input_slew, C_load, metric, value]`
- `power_raw.csv`: Raw power data with columns `[cell_type, from_pin, to_pin, input_slew, C_load, metric, value]`
- `delay_train.csv`: Training data with columns `[cell_type, from_pin, to_pin, input_slew, C_load, D_cell, output_slew]`
- `power_train.csv`: Training data with columns `[cell_type, from_pin, to_pin, input_slew, C_load, P_internal]`



