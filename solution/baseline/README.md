# Baseline flow (OpenROAD)

This baseline runs a minimal OpenROAD pass (resizer + timing repair + detail placement for legalization) on the current design using the environment exported by `run.sh`.

## What it does
- Reads LEF/LIB from `TECH_DIR`.
- Loads `contest.v`, `contest.def`, and `contest.sdc` from `DESIGN_DIR`.
- Applies `repair_design`, `repair_timing`, and `detailed_placement`.
- Writes `contest.v` and `contest.def` to `OUTPUT_DIR`.
