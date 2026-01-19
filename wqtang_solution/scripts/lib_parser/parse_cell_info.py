import re
import os
import json

def _extract_size_type_token(cell_str: str) -> str:
    """
    Extract the original drive/size token from the cell name, e.g.
    "x1", "xp5", "x2", "xp33". This keeps the exact token from the name
    to distinguish sizing variants among functionally-identical cells.
    """
    name = cell_str if 'ASAP' not in cell_str else cell_str[:cell_str.find('ASAP') - 1]
    # token between last 'x' and the next '_' (or end of string if no '_')
    m = re.search(r"x[^_]+", name[::-1])  # reverse search helper (fallback)
    # Prefer a forward regex: 'x' followed by digits/letters up to '_' or end
    m2 = re.search(r"x[^_]+", name[name.rfind('x'):] if 'x' in name else '')
    token = ''
    if m2:
        token = m2.group(0)
    return token

def _normalize_boolean_function(expr: str) -> str:
    """
    Produce a normalized function string for equality checks:
    - strip quotes and spaces
    - keep operator symbols as-is; we rely on exact match after whitespace removal
    """
    if not isinstance(expr, str):
        return ''
    s = expr.strip()
    if s.startswith('"') and s.endswith('"'):
        s = s[1:-1]
    # remove all whitespace to make equality more robust to spacing
    s = re.sub(r"\s+", "", s)
    return s

def parse_cellname(cell_str: str):
    """
    parse the cell name and get the following information:
        cell_type: e.g. AND, SRAM
        load: load capacitance (or size indicator for memory)

    :param cell_str: str
            cell name

    :return:
        cell_type: str
        load: float
    """

    cell_name = cell_str if 'ASAP' not in cell_str \
        else cell_str[:cell_str.find('ASAP') - 1]  # e.g., AND2x6, AOI21xp33

    # Special handling for SRAM cells
    if cell_name.startswith('sram') or 'sram' in cell_name.lower():
        # For SRAM like "sram_asap7_64x256_1rw", extract memory size as load
        # Pattern: sram_*_WIDTHxDEPTH_*
        sram_match = re.search(r'(\d+)x(\d+)', cell_name)
        if sram_match:
            width = int(sram_match.group(1))
            depth = int(sram_match.group(2))
            load = float(width * depth)  # Use memory capacity as load
        else:
            load = 1.0  # fallback
        return "SRAM", load

    # Standard logic cell handling
    if 'x' not in cell_name:
        # No drive strength indicator, treat as single type
        return cell_name, 1.0
    
    # extract the cell type first,
    cell_type = cell_name[:cell_name.rfind('x')]
    idx = re.search('\d', cell_type)
    if idx is not None and not cell_type.startswith('A2') and not cell_type.startswith('O2'):
        cell_type = cell_type[:idx.start()]
    
    # extract the cell load/drive strength
    load = cell_name[cell_name.rfind('x') + 1:]
    #if '_' in load: load = load[:load.find('_')]
    if load.startswith('p'):
        load = '0'+load
    load = load.replace('p', '.')
    alpha_idx = re.search('[a-zA-Z]',load)
    if alpha_idx is not None:
        load = load[:alpha_idx.start()]
    try:
        load = float(load)
    except ValueError:
        load = 0.0
    return cell_type, load

def main():
    cell_info_map_path = './cell_info_map.json'
    ctype2id_path = './ctype2id.json'
    output_json_path = './lib_info.json'

    # Check if output files already exist
    if os.path.exists(cell_info_map_path) and os.path.exists(ctype2id_path):
        print(f'cell_info map already exists in {cell_info_map_path}')
        return

    # Load cell map from lib_info.json
    if not os.path.exists(output_json_path):
        print(f'Error: {output_json_path} does not exist.')
        return

    with open(output_json_path, 'r') as f:
        cell_map = json.load(f)

    # Map of function-based type key -> incremental id
    function_key_to_id = {}
    # Map of function-based type key -> short, cellname-based type label
    function_key_to_short_type = {}
    used_short_types = set()
    base_type_counts = {}
    next_function_id = 0
    for cell, cell_info in cell_map.items():
        cell_type, load = parse_cellname(cell)
        new_pininfo = {}
        output_functions = {}
        normalized_outputs = {}
        for pin, pin_info in cell_info.get('pin_info', {}).items():
            # Remove bus index and spaces from pin name
            if '[' in pin:
                pin = pin[:pin.find('[')]
            pin = pin.replace(' ', '')
            new_pininfo[pin] = pin_info
            # Collect function for output pins (string may be empty if absent)
            if isinstance(pin_info, dict) and pin_info.get('direction', '') == 'output':
                func_raw = pin_info.get('function', '') or ''
                output_functions[pin] = func_raw
                normalized_outputs[pin] = _normalize_boolean_function(func_raw)
        cell_info['pin_info'] = new_pininfo

        # Keep numeric load parsed from name
        cell_info['load'] = load
        # Attach an aggregated mapping of output pin -> function string
        cell_info['output_functions'] = output_functions

        # Build a function_key to group functionally-identical cells
        # Include pin structure (names and directions) + output functions
        pin_structure = []
        for pin_name in sorted(new_pininfo.keys()):
            pin_info = new_pininfo[pin_name]
            direction = pin_info.get('direction', 'unknown') if isinstance(pin_info, dict) else 'unknown'
            pin_structure.append(f"{pin_name}:{direction}")
        
        # Combine pin structure with output functions for complete signature
        if normalized_outputs:
            output_parts = [f"{p}:{normalized_outputs[p]}" for p in sorted(normalized_outputs.keys())]
            function_key = f"PINS[{';'.join(pin_structure)}]_FUNCS[{';'.join(output_parts)}]"
        else:
            # No output function; still include pin structure to distinguish by interface
            function_key = f"PINS[{';'.join(pin_structure)}]_NO_FUNCS"
        cell_info['function_key'] = function_key
        if function_key not in function_key_to_id:
            function_key_to_id[function_key] = next_function_id
            # Propose a short type label based on the cell name-derived type
            base_short = cell_type if cell_type else 'TYPE'
            if function_key.startswith('NO_OUTPUT::'):
                base_short = f"{base_short}_NOFUNC"
            # ensure uniqueness of short type labels
            candidate = base_short
            if candidate in used_short_types:
                idx = base_type_counts.get(base_short, 1)
                while f"{base_short}_{idx}" in used_short_types:
                    idx += 1
                candidate = f"{base_short}_{idx}"
                base_type_counts[base_short] = idx + 1
            else:
                base_type_counts.setdefault(base_short, 1)
            used_short_types.add(candidate)
            function_key_to_short_type[function_key] = candidate
            next_function_id += 1
        cell_info['functional_id'] = function_key_to_id[function_key]

        # Derive a size_type token from the original cell name to distinguish
        # sizing/layout variants within the same functional group
        if cell_type == "SRAM":
            # For SRAM, use only the dimension as size_type (e.g., "64x256")
            sram_config_match = re.search(r'(\d+x\d+)', cell)
            cell_info['size_type'] = sram_config_match.group(1) if sram_config_match else cell
        else:
            cell_info['size_type'] = _extract_size_type_token(cell)

        # Set type/type_id strictly based on function equality
        cell_info['type'] = function_key_to_short_type.get(function_key, cell_type or 'TYPE')
        cell_info['type_id'] = function_key_to_id[function_key]
        cell_map[cell] = cell_info

    print("Functional group count:", len(function_key_to_id))

    # Save the result
    with open(cell_info_map_path, 'w') as f:
        json.dump(cell_map, f, indent=2)
    # Export mapping from short type label -> id for readability
    short_type_to_id = {function_key_to_short_type[k]: v for k, v in function_key_to_id.items()}
    with open(ctype2id_path, 'w') as f:
        json.dump(short_type_to_id, f, indent=2)

if __name__ == '__main__':
    main()
