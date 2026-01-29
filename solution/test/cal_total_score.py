
#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

baseline = {
    "aes_cipher_top": {
        "tns": -311.27,
        "dpower": 70091000000,
        "lpower": 109000000,
        "slew_over_sum": 539.39,
        "cap_over_sum": 0.31,
        "fanout_over_sum": 0,
        "tool_runtime": 54,
        "flow_runtime": 7,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "aes_cipher_top_v2": {
        "tns": -109.5143,
        "dpower": 305911830000,
        "lpower": 118170000,
        "slew_over_sum": 259.873,
        "cap_over_sum": 0.2828,
        "fanout_over_sum": 0.01,
        "tool_runtime": 116,
        "flow_runtime": 6,
        "max_gr_overflow": 0.01,
        "total_gr_overflow": 0.01,
        "displacement": 0.3131,
    },
    "ariane": {
        "tns": -1097386.88,
        "dpower": 147380000000,
        "lpower": 5620000000,
        "slew_over_sum": 1732406.82,
        "cap_over_sum": 50.99,
        "fanout_over_sum": 0,
        "tool_runtime": 792,
        "flow_runtime": 70,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "ariane_v2": {
        "tns": -192248.58,
        "dpower": 132920000000,
        "lpower": 5080000000,
        "slew_over_sum": 278972.32,
        "cap_over_sum": 78.79,
        "fanout_over_sum": 146927,
        "tool_runtime": 1323,
        "flow_runtime": 50,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "bsg_chip": {
        "tns": -489273.34,
        "dpower": 767800000000,
        "lpower": 37200000000,
        "slew_over_sum": 665351.73,
        "cap_over_sum": 281.1,
        "fanout_over_sum": 0,
        "tool_runtime": 1851,
        "flow_runtime": 1515,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "bsg_chip_v2": {
        "tns": -651923.75,
        "dpower": 1645200000000,
        "lpower": 34800000000,
        "slew_over_sum": 1096020.61,
        "cap_over_sum": 561.03,
        "fanout_over_sum": 0,
        "tool_runtime": 1185,
        "flow_runtime": 678,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "jpeg_encoder": {
        "tns": -19920.66,
        "dpower": 185719000000,
        "lpower": 281000000,
        "slew_over_sum": 57206.73,
        "cap_over_sum": 6.34,
        "fanout_over_sum": 0,
        "tool_runtime": 205,
        "flow_runtime": 9,
        "max_gr_overflow": 0,
        "total_gr_overflow": 0,
        "displacement": 0,
    },
    "jpeg_encoder_v2": {
        "tns": -16853.2842,
        "dpower": 169460830000,
        "lpower": 219170000,
        "slew_over_sum": 21311.4747,
        "cap_over_sum": 6.9589,
        "fanout_over_sum": 0.01,
        "tool_runtime": 214,
        "flow_runtime": 10,
        "max_gr_overflow": 0.01,
        "total_gr_overflow": 0.01,
        "displacement": 0.0606,
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


def compute_s_final(d: dict, debug = True) -> str:
    w_tns = 80.0
    w_dpower = 40.0
    w_lpower = 40.0
    w_slew = 0.001
    w_cap = 10.0
    w_fanout = 1.0
    w_flowRuntime = 1.0
    w_maxOverflow = 1.0
    w_totalOverflow = 1.0
    w_toolRuntime = 0.5
    w_dis = 0.5
    ethlon = 1e-8

    design = d.get("design")
    Chc = to_float(d.get("Chc"),default=1.0)    
    tns = to_float(d.get("tns"))
    dpower = to_float(d.get("total_power")) - to_float(d.get("leakage_power"))
    lpower = to_float(d.get("leakage_power"))
    slew_over_sum = to_float(d.get("slew_over_sum"))
    cap_over_sum = to_float(d.get("cap_over_sum"))
    fanout_over_sum = to_float(d.get("fanout_over_sum"))
    tool_runtime = to_float(d.get("tool_runtime"))
    flow_runtime = to_float(d.get("flow_runtime"))
    max_gr_overflow = to_float(d.get("max_gr_overflow"))
    total_gr_overflow = to_float(d.get("total_gr_overflow"))
    displacement = to_float(d.get("displacement"))

    #SPPA = w_tns * (-tns + baseline.get(design).get("tns")) / abs(-baseline.get(design).get("tns") + ethlon) + w_dpower * (baseline.get(design).get("dpower") - dpower) / baseline.get(design).get("dpower") + w_lpower * (baseline.get(design).get("lpower") - lpower) / baseline.get(design).get("lpower")
    SPPA = (
        w_tns * (tns - baseline.get(design).get("tns"))
        / abs(baseline.get(design).get("tns") + ethlon)
        + w_dpower
        * (baseline.get(design).get("dpower") - dpower)
        / baseline.get(design).get("dpower")
        + w_lpower
        * (baseline.get(design).get("lpower") - lpower)
        / baseline.get(design).get("lpower")
    )
    if(debug):
        print("TNS: ", w_tns * (tns - baseline.get(design).get("tns")) / abs(baseline.get(design).get("tns") + ethlon))
        print("DPower: ", w_dpower * (baseline.get(design).get("dpower") - dpower) / baseline.get(design).get("dpower"))
        print("LPower: ", w_lpower * (baseline.get(design).get("lpower") - lpower) / baseline.get(design).get("lpower"))
        print("SPPA: ", SPPA)


    #PERC = w_slew * (slew_over_sum - baseline.get(design).get("slew_over_sum")) / (baseline.get(design).get("slew_over_sum") + ethlon) + w_cap * (cap_over_sum - baseline.get(design).get("cap_over_sum")) / (baseline.get(design).get("cap_over_sum") + ethlon) + w_fanout * (fanout_over_sum - baseline.get(design).get("fanout_over_sum")) / (baseline.get(design).get("fanout_over_sum") + ethlon)
    PERC = (
        w_slew
        * (slew_over_sum - baseline.get(design).get("slew_over_sum"))
        / (baseline.get(design).get("slew_over_sum") + ethlon)
        + w_cap
        * (cap_over_sum - baseline.get(design).get("cap_over_sum"))
        / (baseline.get(design).get("cap_over_sum") + ethlon)
        + w_fanout
        * (fanout_over_sum - baseline.get(design).get("fanout_over_sum"))
        / (baseline.get(design).get("fanout_over_sum") + ethlon)
    )    
    if(debug):
        print("Slew: ", w_slew * (slew_over_sum - baseline.get(design).get("slew_over_sum")) / (baseline.get(design).get("slew_over_sum") + ethlon))
        print("Cap: ", w_cap * (cap_over_sum - baseline.get(design).get("cap_over_sum")) / (baseline.get(design).get("cap_over_sum") + ethlon))
        print("Fanout: ", w_fanout * (fanout_over_sum - baseline.get(design).get("fanout_over_sum")) / (baseline.get(design).get("fanout_over_sum") + ethlon))
        print("PERC: ", PERC)

    R = w_flowRuntime * (flow_runtime - baseline.get(design).get("flow_runtime")) / baseline.get(design).get("flow_runtime") + w_toolRuntime * (tool_runtime - baseline.get(design).get("tool_runtime")) / baseline.get(design).get("tool_runtime")
    if(debug):
        print("Flow Runtime: ", w_flowRuntime * (flow_runtime - baseline.get(design).get("flow_runtime")) / baseline.get(design).get("flow_runtime"))
        print("Tool Runtime: ", w_toolRuntime * (tool_runtime - baseline.get(design).get("tool_runtime")) / baseline.get(design).get("tool_runtime"))
        print("R: ", R)

    Pdis =  w_dis * (displacement - baseline.get(design).get("displacement")) / (baseline.get(design).get("displacement") + ethlon)
    if(debug):
        print("Displacement: ", w_dis * (displacement - baseline.get(design).get("displacement")) / (baseline.get(design).get("displacement") + ethlon))
        print("Pdis: ", Pdis)

    #Poverflow = w_maxOverflow * (max_gr_overflow - baseline.get(design).get("max_gr_overflow")) / (baseline.get(design).get("max_gr_overflow") + ethlon) + w_totalOverflow * (total_gr_overflow - baseline.get(design).get("total_gr_overflow")) / (baseline.get(design).get("total_gr_overflow") + ethlon)
    Poverflow = (
        w_maxOverflow
        * (max_gr_overflow - baseline.get(design).get("max_gr_overflow"))
        / (baseline.get(design).get("max_gr_overflow") + ethlon)
        + w_totalOverflow
        * (total_gr_overflow - baseline.get(design).get("total_gr_overflow"))
        / (baseline.get(design).get("total_gr_overflow") + ethlon)
    )
    print("Max GR Overflow: ", w_maxOverflow * (max_gr_overflow - baseline.get(design).get("max_gr_overflow")) / (baseline.get(design).get("max_gr_overflow") + ethlon))
    print("Total GR Overflow: ", w_totalOverflow * (total_gr_overflow - baseline.get(design).get("total_gr_overflow")) / (baseline.get(design).get("total_gr_overflow") + ethlon))
    print("Poverflow: ", Poverflow)


    s_final = Chc * (SPPA - PERC - R - Pdis - Poverflow)  
    print("Chc: ", Chc)
    print("S_final: ", str(s_final))     
    if(lpower == 0.0):
        s_final = 0

    
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
