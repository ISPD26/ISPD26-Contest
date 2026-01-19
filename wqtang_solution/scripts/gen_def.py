#!/usr/bin/env python3
"""
Generate a modified DEF file with random cell replacements and position movements.

Usage: gen_def.py <ori_def> <out_def> <replace_percentage> <move_percentage>

- replace_percentage: Percentage of cells to replace with same-type cells (0-100)
- move_percentage: Percentage of cells to randomly move (0-100)
"""

import sys
import json
import random
import re
from pathlib import Path


def load_cell_table(cell_table_path):
    """Load the cell type mapping from cell_table.json"""
    with open(cell_table_path, 'r') as f:
        return json.load(f)


def find_cell_type(cell_name, cell_table):
    """
    Find the cell type category for a given cell name.
    Returns (type_category, cell_list) or (None, None) if not found.
    """
    for cell_type, cell_list in cell_table.items():
        if cell_name in cell_list:
            return cell_type, cell_list
    return None, None


def parse_def_file(def_path):
    """
    Parse a DEF file and return its contents as sections.
    Returns: (header_lines, components, footer_lines, die_area)
    """
    with open(def_path, 'r') as f:
        lines = f.readlines()

    header_lines = []
    components = []
    footer_lines = []
    die_area = None

    in_components = False
    component_buffer = ""

    for line in lines:
        # Check for DIEAREA to extract boundaries
        if line.strip().startswith('DIEAREA'):
            die_area = parse_diearea(line)

        # Check for COMPONENTS section start
        if line.startswith('COMPONENTS') and 'END COMPONENTS' not in line:
            in_components = True
            header_lines.append(line)
            continue

        # Check for COMPONENTS section end
        if line.strip().startswith('END COMPONENTS'):
            if component_buffer:
                components.append(component_buffer.rstrip())
            in_components = False
            footer_lines.append(line)
            continue

        if in_components:
            # Components can span multiple lines, look for semicolons
            component_buffer += line
            if ';' in line:
                components.append(component_buffer.rstrip())
                component_buffer = ""
        elif not in_components and not component_buffer:
            if not components:  # Still in header
                header_lines.append(line)
            else:  # In footer
                footer_lines.append(line)

    return header_lines, components, footer_lines, die_area


def parse_diearea(diearea_line):
    """Parse DIEAREA line to extract boundaries.
    Example: DIEAREA ( 0 0 ) ( 42912 42516 ) ;
    Returns: (min_x, min_y, max_x, max_y)
    """
    match = re.search(r'\(\s*(\d+)\s+(\d+)\s*\).*\(\s*(\d+)\s+(\d+)\s*\)', diearea_line)
    if match:
        return (int(match.group(1)), int(match.group(2)),
                int(match.group(3)), int(match.group(4)))
    return (0, 0, 50000, 50000)  # Default values


def parse_component(component_str):
    """
    Parse a component entry from the DEF file.
    Returns: (instance_name, cell_type, x, y, orientation, full_line_parts)
    """
    # Match pattern: - <instance_name> <cell_type> ... PLACED ( x y ) orientation
    match = re.match(r'-\s+([\S]+)\s+([\S]+)(.*?)PLACED\s*\(\s*(\d+)\s+(\d+)\s*\)\s*(\w+)',
                     component_str, re.DOTALL)

    if not match:
        return None

    instance_name = match.group(1)
    cell_type = match.group(2)
    middle_part = match.group(3)
    x = int(match.group(4))
    y = int(match.group(5))
    orientation = match.group(6)

    # Handle escaped brackets in instance name
    instance_name = instance_name.replace('\\[', '[').replace('\\]', ']')

    return instance_name, cell_type, x, y, orientation, middle_part


def generate_random_displacement(die_area, displacement_ratio=0.1):
    """
    Generate random displacement within a reasonable range.
    displacement_ratio: fraction of die area to use as max displacement
    """
    min_x, min_y, max_x, max_y = die_area
    max_dx = int((max_x - min_x) * displacement_ratio)
    max_dy = int((max_y - min_y) * displacement_ratio)

    dx = random.randint(-max_dx, max_dx)
    dy = random.randint(-max_dy, max_dy)

    return dx, dy


def clamp_coordinates(x, y, die_area):
    """Clamp coordinates to stay within die area"""
    min_x, min_y, max_x, max_y = die_area
    x = max(min_x, min(x, max_x))
    y = max(min_y, min(y, max_y))
    return x, y


def modify_components(components, cell_table, replace_pct, move_pct, die_area):
    """
    Modify components by replacing cells and moving positions.
    Returns: modified_components list
    """
    modified_components = []
    total_components = len(components)

    # Determine which components to replace and move
    num_to_replace = int(total_components * replace_pct / 100.0)
    num_to_move = int(total_components * move_pct / 100.0)

    # Random selection of indices
    replace_indices = set(random.sample(range(total_components), num_to_replace))
    move_indices = set(random.sample(range(total_components), num_to_move))

    print(f"Total components: {total_components}")
    print(f"Components to replace: {num_to_replace} ({replace_pct}%)")
    print(f"Components to move: {num_to_move} ({move_pct}%)")

    replaced_count = 0
    moved_count = 0

    for idx, component in enumerate(components):
        parsed = parse_component(component)

        if not parsed:
            # Keep unparseable components as-is
            modified_components.append(component)
            continue

        instance_name, cell_type, x, y, orientation, middle_part = parsed
        new_cell_type = cell_type
        new_x, new_y = x, y

        # Replace cell type if selected
        if idx in replace_indices:
            cell_category, cell_list = find_cell_type(cell_type, cell_table)
            if cell_category and len(cell_list) > 1:
                # Select a different cell from the same type
                other_cells = [c for c in cell_list if c != cell_type]
                if other_cells:
                    new_cell_type = random.choice(other_cells)
                    replaced_count += 1

        # Move position if selected
        if idx in move_indices:
            dx, dy = generate_random_displacement(die_area)
            new_x = x + dx
            new_y = y + dy
            new_x, new_y = clamp_coordinates(new_x, new_y, die_area)
            moved_count += 1

        # Reconstruct the component line
        # Escape brackets in instance name for DEF format
        escaped_instance = instance_name.replace('[', '\\[').replace(']', '\\]')

        new_component = f"- {escaped_instance} {new_cell_type}{middle_part}PLACED ( {new_x} {new_y} ) {orientation}"
        modified_components.append(new_component)

    print(f"Actually replaced: {replaced_count} cells")
    print(f"Actually moved: {moved_count} cells")

    return modified_components


def write_def_file(out_path, header_lines, components, footer_lines):
    """Write the modified DEF file"""
    with open(out_path, 'w') as f:
        # Write header
        for line in header_lines:
            # Update component count if in COMPONENTS line
            if line.startswith('COMPONENTS'):
                f.write(f"COMPONENTS {len(components)} ;\n")
            else:
                f.write(line)

        # Write components
        for component in components:
            f.write(component)
            if not component.endswith('\n'):
                f.write('\n')
            # Add semicolon if missing
            if not component.rstrip().endswith(';'):
                f.write(' ;\n')

        # Write footer
        for line in footer_lines:
            f.write(line)


def main():
    if len(sys.argv) != 5:
        print("Usage: gen_def.py <ori_def> <out_def> <replace_percentage> <move_percentage>")
        print("  ori_def: Path to original DEF file")
        print("  out_def: Path to output DEF file")
        print("  replace_percentage: Percentage of cells to replace (0-100)")
        print("  move_percentage: Percentage of cells to move (0-100)")
        sys.exit(1)

    ori_def = sys.argv[1]
    out_def = sys.argv[2]
    replace_pct = float(sys.argv[3])
    move_pct = float(sys.argv[4])

    # Validate percentages
    if not (0 <= replace_pct <= 100) or not (0 <= move_pct <= 100):
        print("Error: Percentages must be between 0 and 100")
        sys.exit(1)

    # Find cell_table.json (assume it's in scripts/lib_parser/)
    script_dir = Path(__file__).parent
    cell_table_path = script_dir / "lib_parser" / "cell_table.json"

    if not cell_table_path.exists():
        print(f"Error: Cell table not found at {cell_table_path}")
        sys.exit(1)

    print(f"Loading cell table from {cell_table_path}")
    cell_table = load_cell_table(cell_table_path)
    print(f"Loaded {len(cell_table)} cell types")

    print(f"\nParsing DEF file: {ori_def}")
    header_lines, components, footer_lines, die_area = parse_def_file(ori_def)
    print(f"Die area: {die_area}")

    print(f"\nModifying components...")
    modified_components = modify_components(components, cell_table, replace_pct, move_pct, die_area)

    print(f"\nWriting output DEF file: {out_def}")
    write_def_file(out_def, header_lines, modified_components, footer_lines)

    print("Done!")


if __name__ == "__main__":
    main()
