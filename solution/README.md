# Solution Runner

`run.sh` is the entrypoint for running a single ISPD26 benchmark through OpenROAD. It wires up the environment, launches the chosen Tcl flow, and writes outputs to the directory you provide.

## Requirements
- Bash environment with `openroad` on `PATH`.

## Basic Usage
```bash
./run.sh <DESIGN_NAME> <TECH_DIR> <DESIGN_DIR> <OUTPUT_DIR> [-t <tcl_name>]
```
- `<DESIGN_NAME>`: benchmark design name, e.g., `aes_cipher_top`.
- `<TECH_DIR>`: technology root, e.g., `/ISPD26-Contest/Platform/ASAP7`.
- `<DESIGN_DIR>`: scenario folder containing `contest.v/def/sdc`.
- `<OUTPUT_DIR>`: destination for generated `contest.v` and `contest.def`.
- `-t <tcl_name>`: optional; picks `solution/tcl/<tcl_name>.tcl` (default `baseline`).

## Example
Run the baseline Tcl on a specific scenario:
```bash
./run.sh aes_cipher_top \
  /ISPD26-Contest/Platform/ASAP7 \
  /ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40 \
  /ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40 \
  -t baseline
```

## What the baseline Tcl does
The default flow (`solution/tcl/baseline.tcl`) loads ASAP7 LEF/LIB, reads the provided netlist/DEF/SDC, sets RC, runs `repair_design` and `repair_timing` for legalization/cleanup, then writes `contest.v` and `contest.def` to your output directory.

## Batch helper
To sweep multiple benchmarks, use `solution/test/test_bench.sh`:
```bash
# Run all bundled cases with baseline.tcl
./solution/test/test_bench.sh -a

# Run a subset with a different Tcl
./solution/test/test_bench.sh -d aes_cipher_top ariane -t baseline
```
