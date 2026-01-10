#!/usr/bin/env python3
import csv
import sys
from pathlib import Path


def to_float(v, default=0.0) -> float:
    if v is None:
        return default
    s = str(v).strip()
    if s == "" or s.lower() in {"na", "nan", "none", "null"}:
        return default
    try:
        return float(s)
    except ValueError:
        return default


def compute_s_final(d: dict) -> str:
    w_tns = 80.0
    w_dpower = 40.0
    w_lpower = 40.0
    w_slew = 0.001
    w_cap = 10.0
    w_fanout = 1.0
    w_flowRuntime = 1.0
    w_maxOverflow = 1.0
    w_totalOverflow = 1.0

    tns = to_float(d.get("tns"))
    lpower = to_float(d.get("leakage_power"))
    slew_over_sum = to_float(d.get("slew_over_sum"))
    cap_over_sum = to_float(d.get("cap_over_sum"))
    fanout_over_sum = to_float(d.get("fanout_over_sum"))
    flow_runtime = to_float(d.get("flow_runtime"))
    max_gr_overflow = to_float(d.get("max_gr_overflow"))
    total_gr_overflow = to_float(d.get("total_gr_overflow"))

    s_final = (
        w_tns * tns
        + w_lpower * lpower
        + w_slew * slew_over_sum
        + w_cap * cap_over_sum
        + w_fanout * fanout_over_sum
        + w_flowRuntime * flow_runtime
        + w_maxOverflow * max_gr_overflow
        + w_totalOverflow * total_gr_overflow
    )

    return str(s_final)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} <out_dir>", file=sys.stderr)
        return 2

    out_dir = Path(sys.argv[1])
    csv_path = out_dir / "metrics.csv"

    if not csv_path.is_file():
        print(f"Error: not found: {csv_path}", file=sys.stderr)
        return 2

    with csv_path.open("r", newline="") as f:
        rows = list(csv.reader(f))

    if not rows:
        print(f"Error: empty csv: {csv_path}", file=sys.stderr)
        return 2

    header = rows[0]
    data_rows = rows[1:]

    if not data_rows:
        print(f"Error: csv has header only (no data rows): {csv_path}", file=sys.stderr)
        return 2

    last_idx = len(data_rows) - 1
    last_row = data_rows[last_idx]

    if len(last_row) < len(header):
        last_row = last_row + [""] * (len(header) - len(last_row))
    elif len(last_row) > len(header):
        header = header + [f"extra_{i}" for i in range(len(header), len(last_row))]

    row_dict = {header[i]: last_row[i] for i in range(len(header))}
    s_final = compute_s_final(row_dict)

    if "S_final" in header:
        s_col = header.index("S_final")
        if len(last_row) <= s_col:
            last_row = last_row + [""] * (s_col + 1 - len(last_row))
        last_row[s_col] = s_final
        data_rows[last_idx] = last_row
    else:
        header.append("S_final")
        new_data_rows = []
        for i, r in enumerate(data_rows):
            r2 = r[:] + [""] * (len(header) - len(r))
            if i == last_idx:
                r2[-1] = s_final
            new_data_rows.append(r2)
        data_rows = new_data_rows

    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(data_rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
