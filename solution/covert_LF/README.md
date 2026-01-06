# convert_lf.sh

Small helper to normalize shell scripts to LF endings.

## What it does
- Scans the target directory for `*.sh` files.
- Strips trailing `\r` so scripts use LF line endings.

## Usage
- From repo root:
  ```bash
  solution/covert_LF/convert_lf.sh <target_dir>
  ```
- If `<target_dir>` is omitted, it defaults to the current directory (`.`).

## Example
```bash
# Fix line endings for all scripts under solution/
solution/covert_LF/convert_lf.sh solution
```
