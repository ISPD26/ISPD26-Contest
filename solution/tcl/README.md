# Tcl Flows

OpenROAD recipes live here and are invoked by `solution/run.sh` via `-t <tcl_name>`.

## Available scripts
- `baseline.tcl`: minimal cleanup/legalization flow.
- `template.tcl`: starter scaffold with tech/design load, RC setup, and output writes—drop your optimization passes into section 4.

## Baseline flow
`baseline.tcl` expects the environment exported by `run.sh`:
- Inputs: `TECH_DIR` (ASAP7 LEF/LIB), `DESIGN_DIR` (contains `contest.v`, `contest.def`, `contest.sdc`), `DESIGN_NAME`, `OUTPUT_DIR`.
- Steps: read tech LEFs/LIBs, load design, set RC/units, run `repair_design` and `repair_timing` (setup only, no gate cloning/pin swap), legalize via detail placement, then write `contest.v` and `contest.def` to `OUTPUT_DIR`.

## Template flow
`template.tcl` mirrors the baseline setup (tech/design load, RC/units, output writes) but leaves the optimization core empty—add your own OpenROAD commands in section 4 before the write-out block.

## Usage
Pick the script with `-t` (omit extension):
```bash
./solution/run.sh <design> <tech_dir> <design_dir> <out_dir> -t baseline
```
