#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

baseline = {
    "aes_cipher_top": {
        "tns": -19.55,
        "dpower": 74479000000,
        "lpower": 121000000,
        "slew_over_sum": 0.0,
        "cap_over_sum": 0.0,
        "fanout_over_sum": 0.0,
        "flow_runtime": 5,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "aes_cipher_top_v2": {
        "tns": -49.56,
        "dpower": 301883000000,
        "lpower": 117000000,
        "slew_over_sum": 1.2,
        "cap_over_sum": 0.02,
        "fanout_over_sum": 0.0,
        "flow_runtime": 4,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "ariane": {
        "tns": -12748.79,
        "dpower": 143330000000,
        "lpower": 5670000000,
        "slew_over_sum": 154.48,
        "cap_over_sum": 0.01,
        "fanout_over_sum": 0.0,
        "flow_runtime": 49,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "ariane_v2": {
        "tns": -31256.91,
        "dpower": 141890000000,
        "lpower": 5110000000,
        "slew_over_sum": 0.14,
        "cap_over_sum": 0.02,
        "fanout_over_sum": 4.0,
        "flow_runtime": 33,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "jpeg_encoder": {
        "tns": -406.37,
        "dpower": 123691000000,
        "lpower": 309000000,
        "slew_over_sum": 0.0,
        "cap_over_sum": 0.0,
        "fanout_over_sum": 0.0,
        "flow_runtime": 7,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "jpeg_encoder_v2": {
        "tns": -851.17,
        "dpower": 166787000000,
        "lpower": 213000000,
        "slew_over_sum": 0.72,
        "cap_over_sum": 0.0,
        "fanout_over_sum": 0.0,
        "flow_runtime": 6,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "bsg_chip": {
        "tns": -119199.7,
        "dpower": 773800000000,
        "lpower": 37200000000,
        "slew_over_sum": 832.24,
        "cap_over_sum": 0.0,
        "fanout_over_sum": 0.0,
        "flow_runtime": 623,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
    "bsg_chip_v2": {
        "tns": -90448.4,
        "dpower": 1735100000000,
        "lpower": 34900000000,
        "slew_over_sum": 444.97,
        "cap_over_sum": 0.01,
        "fanout_over_sum": 0.0,
        "flow_runtime": 354,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
    },
}


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
    ethlon = 0.000001

    design = d.get("design")
    tns = to_float(d.get("tns"))
    dpower = to_float(d.get("total_power")) - to_float(d.get("leakage_power"))
    lpower = to_float(d.get("leakage_power"))
    slew_over_sum = to_float(d.get("slew_over_sum"))
    cap_over_sum = to_float(d.get("cap_over_sum"))
    fanout_over_sum = to_float(d.get("fanout_over_sum"))
    flow_runtime = to_float(d.get("flow_runtime"))
    max_gr_overflow = to_float(d.get("max_gr_overflow"))
    total_gr_overflow = to_float(d.get("total_gr_overflow"))

    s_final = (
        w_tns * (-tns + baseline.get(design).get("tns")) / abs(-baseline.get(design).get("tns") + ethlon)
        + w_dpower * (baseline.get(design).get("dpower") - dpower) / baseline.get(design).get("dpower")
        + w_lpower * (baseline.get(design).get("lpower") - lpower) / baseline.get(design).get("lpower")
        + w_slew * (slew_over_sum - baseline.get(design).get("slew_over_sum")) / (baseline.get(design).get("slew_over_sum") + ethlon)
        + w_cap * (cap_over_sum - baseline.get(design).get("cap_over_sum")) / (baseline.get(design).get("cap_over_sum") + ethlon)
        + w_fanout * (fanout_over_sum - baseline.get(design).get("fanout_over_sum")) / (baseline.get(design).get("fanout_over_sum") + ethlon)
        + w_flowRuntime * (flow_runtime - baseline.get(design).get("flow_runtime")) / baseline.get(design).get("flow_runtime")
        + w_maxOverflow * (max_gr_overflow - baseline.get(design).get("max_gr_overflow")) / (baseline.get(design).get("max_gr_overflow") + ethlon)
        + w_totalOverflow * (total_gr_overflow - baseline.get(design).get("total_gr_overflow")) / (baseline.get(design).get("total_gr_overflow") + ethlon)
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
