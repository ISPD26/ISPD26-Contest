# ICCAD 2025 Problem C - Team CADC1001

## Environment Setup

Make sure to use this conda environment inside the container for development:

```bash
source /opt/conda/etc/profile.d/conda.sh
source /opt/conda/etc/profile.d/mamba.sh
mamba activate probC_env
```


## Configure Environment Dependencies

```bash
./setup_environment.sh
```


## Optimization Script for 2025 CAD Contest

**Usage:** `./run.sh <design_name> <WL_weight, alpha> <power_weight, beta> <timing_weight, gamma>`

**Example:** `./run.sh aes_cipher_top 123.45 12.345 1.2345`


## Binary Tools

The following binary tools are available in the `./bin` directory for individual use:


### gen_changelist

Generates a changelist file comparing two DEF files to identify cell resizing and buffer insertions.

**Usage:** `./bin/gen_changelist <original_def> <optimized_def> <output_changelist>`

**Example:** `./bin/gen_changelist ./testcases/aes_cipher_top/aes_cipher_top.def ./output/aes_cipher_top/optimization/aes_cipher_top.def ./output/aes_cipher_top/aes_cipher_top.changelist`


### calc_displacement

Calculates displacement metrics between original and optimized placements, including total displacement, average displacement per cell, and movement statistics.

**Usage:** `./bin/calc_displacement <original_def> <optimized_def>`

**Example:** `./bin/calc_displacement ./testcases/aes_cipher_top/aes_cipher_top.def ./output/aes_cipher_top/optimization/aes_cipher_top.def`


### filter_backslash

Filters and processes backslash characters in files, removing escape sequences while preserving backslash-newline combinations.

**Usage:** `./bin/filter_backslash <input_file> <output_file>`

**Example:** `./bin/filter_backslash ./input/file.def ./output/file_filtered.def`


### Building Binary Tools

To build all binary tools from source:

```bash
make
```

To build individual tools:

```bash
make gen_changelist
make calc_displacement
make filter_backslash
```

To clean all built binaries:

```bash
make clean
```

**Requirements:** The build process requires g++ with C++17 support and standard libraries.



## DREAMPlace Development

### make_dreamplace.sh
If you modify any files in `./extpkgs/DREAMPlace/`, you can use `./make_dreamplace.sh` to automatically build and install DREAMPlace with your changes.

**Usage:** `./make_dreamplace.sh`