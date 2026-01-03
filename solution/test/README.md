# Benchmark Test Script — `test_benchmarks.sh`

## Overview
`test_benchmarks.sh` is a helper script for **running benchmark tests**.
It supports:
- Running **all benchmarks**
- Running a **single specified benchmark**

In addition, the script provides an option to control whether the **Baseline algorithm** is used.

---

## Usage

### Basic Usage
```bash
./test_benchmarks.sh [--design <design_name>]
```

- **No arguments**: run all benchmarks
- `--design <design_name>`: run only the specified benchmark

---

## Examples

### 1. Run all benchmarks
```bash
./test_benchmarks.sh
```

### 2. Run a single benchmark
```bash
./test_benchmarks.sh --design aes_cipher_top
```

---

## Baseline Algorithm Control

The `RUN_BASELINE` environment variable controls whether the **Baseline algorithm** is used.

### Syntax
```bash
./test_benchmarks.sh [RUN_BASELINE=0|1]
```

- `RUN_BASELINE=1` (default): use the **Baseline algorithm**
- `RUN_BASELINE=0`: use an **alternative (non-baseline) algorithm**

---

## Examples

### 1. Use a non-baseline algorithm
```bash
./test_benchmarks.sh RUN_BASELINE=0
```

### 2. Use the baseline algorithm
```bash
./test_benchmarks.sh RUN_BASELINE=1
```

---

## Notes
- `RUN_BASELINE` is an **environment variable** and must be specified on the same command line
- `--design` and `RUN_BASELINE` can be used together

```bash
./test_benchmarks.sh --design aes_cipher_top RUN_BASELINE=0
```
