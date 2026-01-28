import sys
from pathlib import Path
import csv

out_dir="/ISPD26-Contest/solution/output"
tcl_name = Path(sys.argv[1])
csv_path = Path(out_dir) / tcl_name

chips={
    "aes_cipher_top": 1,
    "aes_cipher_top_v2": 1,
    "ariane": 1.2,
    "ariane_v2": 1.2,
    "bsg_chip": 1.5,
    "bsg_chip_v2": 1.5,
    "jpeg_encoder": 1,
    "jpeg_encoder_v2": 1,
}



output_csv = csv_path / "final_score.csv"

rows = []
weighted_sum = 0.0

for chip, weight in chips.items():

    metrics_list = list((csv_path / chip).glob("*/metrics.csv"))
    assert len(metrics_list) == 1
    metrics_csv = metrics_list[0]

    with open(metrics_csv, newline="") as f:
        reader = csv.DictReader(f)
        data = next(reader)          # 假設只有一行結果
        score = float(data["S_final"])

    rows.append({
        "chip": chip,
        "score": score,
        "weighted_score": score * weight,
    })

    weighted_sum += score * weight

with open(output_csv, "w", newline="") as f:
    fieldnames = ["chip", "score", "weighted_score"]
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)
    writer.writerow({
        "chip": "final_score",
        "score": "",
        "weighted_score": weighted_sum,
    })
