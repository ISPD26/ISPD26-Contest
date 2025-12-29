# Netlist Equivalence Check

This directory contains scripts for validating equivalence between pre-optimization and post-optimization netlists for ASAP7 designs.

## Overview

The equivalence checker validates that optimized netlists maintain functional equivalence with the original pre-optimization netlists. It performs the following checks:

1. **Instance Presence** - All pre-opt instances exist in post-opt with valid cell substitutions
2. **Buffer/Inverter Path Validity** - Newly added cells must be buffers/inverters with valid connectivity
3. **Physical Cell Location Immutability** - Physical cells (not in equivalent cell list) must not move
4. **Macro Location Immutability** - Macro locations must remain unchanged
5. **I/O Port Location Check** - I/O port locations must remain unchanged

## Files

| File | Description |
|------|-------------|
| `or_utils.tcl` | OpenROAD Tcl utilities to export `node.csv` and `nets.csv` |
| `netlist_equiv_check.py` | Python script to perform equivalence checking |

## Pre-requisites

### Pre-optimization Benchmark Data

Pre-extracted `node.csv` and `nets.csv` files for the benchmarks are available at:

```
./Benchmarks/
```

Directory structure:
```
benchmarks/
├── aes_cipher_top/
│   └── TCP_250_UTIL_0.40/
│       ├── node.csv
│       └── nets.csv
├── aes_cipher_top_v2/
├── ariane/
├── ariane_v2/
├── bsg_chip/
├── bsg_chip_v2/
├── jpeg_encoder/
└── jpeg_encoder_v2/
```

### ASAP7 Equivalent Cell List

The equivalent cell mapping file is located at:
```
./equiv_check/asap7_equivalent_cell_list.csv
```

This file defines groups of functionally equivalent cells (e.g., cells with different drive strengths or threshold voltage variants like `_L`, `_R`, `_SL`).

## Usage

### Step 1: Export Post-Optimization Netlist Data

Use the `or_utils.tcl` functions in OpenROAD to export `node.csv` and `nets.csv` from your optimized design:

```tcl
# Source the utility functions
source or_utils.tcl

# Load your optimized design
# ... (your design loading commands)

# Write out the node and net files
write_node_and_net_files "node.csv" "nets.csv"
```
You can refer to `run_equiv_check.sh` in the folder scripts/{design}.

The exported files have the following formats:

**node.csv:**
```
Name,Master,Type,llx,lly
instance_name,master_cell,Inst|Macro|IO,x_coord,y_coord
```

**nets.csv:**
```
net_name,driver_inst pin_name,sink1_inst pin_name,sink2_inst pin_name,...
```
For I/O ports, the format is `port_name _IO_`.

### Step 2: Run Equivalence Check

Run the equivalence checker with paths to the pre-opt and post-opt directories:

```bash
python3 netlist_equiv_check.py \
    --pre_opt ../Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40 \
    --post_opt /path/to/your/optimized/design/
```

#### Optional Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--pre_opt` | Path to pre-optimization directory (required) | - |
| `--post_opt` | Path to post-optimization directory (required) | - |
| `--equiv_cells` | Path to equivalent cells CSV file | `./equiv_check/asap7_equivalent_cell_list.csv` |

### Example Output

```
Loading data...
Pre-opt: 15234 nodes, 14892 nets
Post-opt: 15456 nodes, 15102 nets
Equivalent cell groups: 89
Buffer masters: 48
Inverter masters: 60

Running Check 1: Instance Presence...
=== CHECK 1: Instance Presence ===
PASS: 0 violations

Running Check 2: Buffer/Inverter Paths...
  Building instance adjacency...
  Checking 45231 driver-sink pairs...
=== CHECK 2: Buffer/Inverter Paths ===
PASS: 0 violations

Running Check 3: Physical Cell Locations...
=== CHECK 3: Physical Cell Locations ===
PASS: 0 violations

Running Check 4: Macro Locations...
=== CHECK 4: Macro Locations ===
PASS: 0 violations

Running Check 5: I/O Port Locations...
=== CHECK 5: I/O Port Locations ===
PASS: 0 violations

==================================================
SUMMARY: 5/5 checks passed
RESULT: Netlists are EQUIVALENT
```

## Check Details

### Check 1: Instance Presence
- **Part A:** All instances from pre-opt must exist in post-opt. Cell substitutions are allowed only within equivalent cell groups.
- **Part B:** Any newly added instances must be buffers or inverters.

### Check 2: Buffer/Inverter Paths
- For each driver-sink connection in pre-opt, there must be a valid path in post-opt.
- Paths may traverse through buffers and inverters.
- The total number of inverters in the path must be even (to preserve signal polarity).

### Check 3: Physical Cell Locations
- Cells NOT listed in the equivalent cell file (physical/hard cells) must not change location.

### Check 4: Macro Locations
- All macro instances must remain at their original locations.

### Check 5: I/O Port Locations
- All I/O ports must remain at their original positions.

## Return Codes

| Code | Meaning |
|------|---------|
| 0 | Netlists are EQUIVALENT (all checks passed) |
| 1 | Netlists are NOT EQUIVALENT (one or more checks failed) |
