# Benchmark Batch Runner

`test_bench.sh` sweeps the bundled ISPD26 benchmarks using `solution/run.sh`, captures logs, and triggers per-design evaluation when available.

## Benchmarks covered
```
aes_cipher_top TCP_250_UTIL_0.40
aes_cipher_top_v2 TCP_200_UTIL_0.40
ariane TCP_900_UTIL_0.30
ariane_v2 TCP_950_UTIL_0.45
bsg_chip TCP_1200_UTIL_0.30
bsg_chip_v2 TCP_1300_UTIL_0.50
jpeg_encoder TCP_350_UTIL_0.70
jpeg_encoder_v2 TCP_450_UTIL_0.65
```

## Usage
```bash
# Run all benchmarks
./test_bench.sh -a [-t <tcl_name>]

# Run selected designs
./test_bench.sh -d <design1> [design2 ...] [-t <tcl_name>]
```
- `-a`: run every listed benchmark.
- `-d`: choose one or more design names from the list above.
- `-t <tcl_name>`: pick `solution/tcl/<tcl_name>.tcl` (default `baseline`).

Outputs go to `/ISPD26-Contest/output/<design>/<scenario>/` with logs in `run.log`. After each run, the script calls `scripts/<design>/eval.sh` if it exists to generate metrics.

## Example
```bash
# Run a subset with the baseline flow
./test_bench.sh -d aes_cipher_top ariane -t baseline
```
