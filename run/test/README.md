# Benchmark test harness

`test_benchmarks.sh` runs the benchmark matrix through `run.sh`.

## Usage
- From repo root: `run/test/test_benchmarks.sh [--design <name>] [run.sh options...]`

## Examples
- Run all benchmarks: `run/test/test_benchmarks.sh`
- Single design: `run/test/test_benchmarks.sh --design aes_cipher_top`
- Single design, skip baseline: `run/test/test_benchmarks.sh --design aes_cipher_top RUN_BASELINE=0`
