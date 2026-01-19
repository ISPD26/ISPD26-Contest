#!/usr/bin/env python3
"""
Parse cell_info_map.json and generate cell_table.json
Groups all cell instances by their functional_id
"""

import json


def generate_cell_table(cell_info_map_path, output_path):
    """
    Generate cell_table.json by grouping cells by their functional_id.

    Args:
        cell_info_map_path: Path to cell_info_map.json
        output_path: Path to output cell_table.json
    """
    # Load and parse cell_info_map.json
    print(f"Loading cell information from {cell_info_map_path}...")
    with open(cell_info_map_path, 'r') as f:
        cell_info_map = json.load(f)

    # Group cells by their functional_id
    print("Grouping cells by functional_id...")
    cell_table = {}

    for cell_name, cell_info in cell_info_map.items():
        functional_id = cell_info.get('functional_id')

        if functional_id is None:
            print(f"Warning: Cell '{cell_name}' has no functional_id, skipping...")
            continue

        if functional_id not in cell_table:
            cell_table[functional_id] = set()

        cell_table[functional_id].add(cell_name)

    # Convert sets to sorted lists for JSON serialization
    cell_table_json = {
        functional_id: sorted(list(cells))
        for functional_id, cells in cell_table.items()
    }

    # Print statistics
    print("\nCell group statistics:")
    for functional_id in sorted(cell_table_json.keys()):
        cells = cell_table_json[functional_id]
        print(f"  functional_id {functional_id}: {len(cells)} instances")

    # Save to output file
    print(f"\nSaving cell table to {output_path}...")
    with open(output_path, 'w') as f:
        json.dump(cell_table_json, f, indent=2)

    print(f"Done! Generated {output_path}")
    return cell_table_json


if __name__ == "__main__":
    # File paths
    cell_info_map_path = "./cell_info_map.json"
    output_path = "./cell_table.json"

    # Generate cell table
    cell_table = generate_cell_table(cell_info_map_path, output_path)
