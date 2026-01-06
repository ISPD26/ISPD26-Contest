#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"

find "$TARGET_DIR" -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
