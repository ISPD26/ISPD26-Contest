# run.sh quick start

`run.sh` drives a single benchmark flow. Provide the design name, tech directory, design directory, and output directory in that order.

## Usage
- `./run.sh <design_name> <tech_dir> <design_dir> <output_dir> [RUN_BASELINE=0|1]`
- `-h` prints the built-in help and exits.

## Arguments
- `design_name`: e.g., `aes_cipher_top`
- `tech_dir`: process technology root, e.g., `/ISPD26-Contest/Platform/ASAP7`
- `design_dir`: benchmark scenario directory, e.g., `/ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40`
- `output_dir`: where results are written, e.g., `/ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40`
- `RUN_BASELINE`: optional; set to `0` to skip the baseline flow (default `1`).

## Example
```bash
./run.sh aes_cipher_top \
  /ISPD26-Contest/Platform/ASAP7 \
  /ISPD26-Contest/Benchmarks/aes_cipher_top/TCP_250_UTIL_0.40 \
  /ISPD26-Contest/output/aes_cipher_top/TCP_250_UTIL_0.40 \
  RUN_BASELINE=1
```
